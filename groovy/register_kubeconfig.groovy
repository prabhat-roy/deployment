import groovy.json.JsonOutput

def getCrumb(String jenkinsUrl, String user, String token) {
    def crumb = sh(
        script: "curl -s --user '${user}:${token}' '${jenkinsUrl}/crumbIssuer/api/json' | jq -r '.crumb'",
        returnStdout: true
    ).trim()
    return crumb
}

def registerKubeconfig() {
    def props = readProperties file: 'Jenkins.env'

    def cloud = props['CLOUD_PROVIDER']?.toLowerCase()
    def jenkinsUrl = props['JENKINS_URL']
    def jenkinsCreds = props['JENKINS_CREDS_ID']

    if (!cloud) error "❌ CLOUD_PROVIDER is not defined"
    if (!jenkinsUrl) error "❌ JENKINS_URL is not defined"
    if (!jenkinsCreds) error "❌ JENKINS_CREDS_ID is not defined"

    def jenkinsAuth = jenkinsCreds.contains(":") ? jenkinsCreds : getUserToken(jenkinsCreds)

    def parts = jenkinsAuth.split(":", 2)
    def jenkinsUser = parts[0].trim()
    def jenkinsToken = parts.length > 1 ? parts[1].trim() : ''

    def credId = "kubeconfig-credential"

    def exists = (sh(script: """
        curl -s -o /dev/null -w "%{http_code}" -u '${jenkinsUser}:${jenkinsToken}' \
        '${jenkinsUrl}/credentials/store/system/domain/_/credential/${credId}/api/json'
    """, returnStdout: true).trim() == "200")

    if (exists) {
        echo "✅ Credential '${credId}' already exists, skipping creation."
        return
    }

    // Copy kubeconfig to workspace (you can replace this line with a real kubeconfig generation step)
    sh "cp ~/.kube/config ${env.WORKSPACE}/kubeconfig"

    def kubeconfigBase64 = sh(
        script: "base64 -w0 ${env.WORKSPACE}/kubeconfig",
        returnStdout: true
    ).trim()

    def payloadMap = [
        "": "0",
        credentials: [
            scope      : "GLOBAL",
            id         : credId,
            description: "Kubeconfig for ${cloud} cluster",
            '$class'   : "org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl",
            fileName   : "config",
            secretBytes: [
                '$class': "org.jenkinsci.plugins.plaincredentials.impl.SecretBytes",
                base64  : kubeconfigBase64
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
         -d @${payloadFile}
    """

    echo "✅ Kubeconfig registered as Jenkins file credential with ID: ${credId}"
}

def getUserToken(String credId) {
    withCredentials([usernamePassword(credentialsId: credId, usernameVariable: 'USER', passwordVariable: 'TOKEN')]) {
        return "${env.USER}:${env.TOKEN}"
    }
}

return this
