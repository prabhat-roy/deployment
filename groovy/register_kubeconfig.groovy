import groovy.json.JsonOutput

def getCrumb(String jenkinsUrl, String user, String token) {
    return sh(
        script: "curl -s --user '${user}:${token}' '${jenkinsUrl}/crumbIssuer/api/json' | jq -r .crumb",
        returnStdout: true
    ).trim()
}

def registerKubeconfig() {
    def props = readProperties file: 'Jenkins.env'

    def cloud = props['CLOUD_PROVIDER']?.toLowerCase()
    def jenkinsUrl = props['JENKINS_URL']
    def jenkinsCreds = props['JENKINS_CREDS_ID']

    if (!cloud) error "❌ CLOUD_PROVIDER is not defined"
    if (!jenkinsUrl) error "❌ JENKINS_URL is not defined"
    if (!jenkinsCreds) error "❌ JENKINS_CREDS_ID is not defined"

    def jenkinsUser = ""
    def jenkinsToken = ""

    if (jenkinsCreds.contains(":")) {
        def parts = jenkinsCreds.split(":", 2)
        jenkinsUser = parts[0].trim()
        jenkinsToken = parts[1].trim()
    } else {
        def tokenPair = getUserToken(jenkinsCreds)
        def parts = tokenPair.split(":", 2)
        jenkinsUser = parts[0].trim()
        jenkinsToken = parts[1].trim()
    }

    def credId = "kubeconfig-credential"

    def existsCode = sh(
        script: """curl -s -o /dev/null -w "%{http_code}" -u '${jenkinsUser}:${jenkinsToken}' \
        '${jenkinsUrl}/credentials/store/system/domain/_/credential/${credId}/api/json'""",
        returnStdout: true
    ).trim()

    if (existsCode == "200") {
        echo "✅ Credential '${credId}' already exists, skipping creation."
        return
    }

    sh "cp ~/.kube/config ${env.WORKSPACE}/kubeconfig"

    def kubeconfigBase64 = sh(
        script: "base64 -w0 ${env.WORKSPACE}/kubeconfig",
        returnStdout: true
    ).trim()

    // Prepare payload
    def payloadMap = [
        "": "0",
        credentials: [
            scope      : "GLOBAL",
            id         : credId,
            description: "Kubeconfig for ${cloud} cluster",
            "\$class"  : "org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl",
            fileName   : "config",
            secretBytes: [
                "\$class": "org.jenkinsci.plugins.plaincredentials.impl.SecretBytes",
                bytes   : kubeconfigBase64
            ]
        ]
    ]

    def payloadFile = "${env.WORKSPACE}/kubeconfig-payload.json"
    writeFile file: payloadFile, text: JsonOutput.toJson(payloadMap)

    def crumb = getCrumb(jenkinsUrl, jenkinsUser, jenkinsToken)

    sh """
    curl -s -X POST '${jenkinsUrl}/credentials/store/system/domain/_/createCredentials' \\
         --user '${jenkinsUser}:${jenkinsToken}' \\
         -H 'Content-Type: application/json' \\
         -H 'Jenkins-Crumb: ${crumb}' \\
         --data-binary @${payloadFile}
    """

    echo "✅ Kubeconfig registered as Jenkins file credential with ID: ${credId}"
}

def getUserToken(String credId) {
    def result = ""
    withCredentials([usernamePassword(credentialsId: credId, usernameVariable: 'USER', passwordVariable: 'TOKEN')]) {
        result = "${env.USER}:${env.TOKEN}"
    }
    return result
}

return this
