import groovy.json.JsonOutput

def getCrumb(String jenkinsUrl, String user, String token) {
    def crumb = sh(
        script: "curl -s --user '${user}:${token}' '${jenkinsUrl}/crumbIssuer/api/json' | jq -r .crumb",
        returnStdout: true
    ).trim()
    echo "🔑 Jenkins crumb: ${crumb}"
    return crumb
}

def getUserToken(String credId) {
    def result = ""
    withCredentials([usernamePassword(credentialsId: credId, usernameVariable: 'USER', passwordVariable: 'TOKEN')]) {
        result = "${env.USER}:${env.TOKEN}"
    }
    return result
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

    // Check if credential exists
    def existsCode = sh(
        script: """curl -s -o /dev/null -w "%{http_code}" -u '${jenkinsUser}:${jenkinsToken}' \
        '${jenkinsUrl}/credentials/store/system/domain/_/credential/${credId}/api/json'""",
        returnStdout: true
    ).trim()

    if (existsCode == "200") {
        echo "✅ Credential '${credId}' already exists, skipping creation."
        return
    }

    // Copy kubeconfig file to workspace
    sh "cp ~/.kube/config ${env.WORKSPACE}/kubeconfig"

    // Read kubeconfig bytes, base64 decode to bytes array for JSON payload
    // We do this in Groovy: read base64 string, decode it, then convert to integer list
    def base64String = sh(
        script: "base64 -w0 ${env.WORKSPACE}/kubeconfig",
        returnStdout: true
    ).trim()

    echo "🔍 Base64 length: ${base64String.length()}"

    // Decode base64 to byte array
    byte[] decodedBytes = base64String.decodeBase64()

    // Convert to list of integers
    def byteList = decodedBytes.collect { b -> b & 0xFF }

    // Compose payload map exactly as Jenkins expects
    def payloadMap = [
        credentials: [
            scope      : "GLOBAL",
            id         : credId,
            description: "Kubeconfig for ${cloud} cluster",
            "\$class"  : "org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl",
            fileName   : "config",
            secretBytes: [
                "\$class": "org.jenkinsci.plugins.plaincredentials.impl.SecretBytes",
                bytes   : byteList
            ]
        ]
    ]

    def payloadFile = "${env.WORKSPACE}/kubeconfig-payload.json"
    def payloadJson = JsonOutput.prettyPrint(JsonOutput.toJson(payloadMap))
    writeFile file: payloadFile, text: payloadJson

    // Debug output: print payload and validate JSON with jq
    echo "📄 Credential payload JSON:"
    sh "cat ${payloadFile}"
    echo "🔎 Validating JSON syntax with jq:"
    sh "jq . ${payloadFile}"

    def crumb = getCrumb(jenkinsUrl, jenkinsUser, jenkinsToken)

    echo "🚀 Sending credential creation request to Jenkins..."

    sh """
    curl -v -X POST '${jenkinsUrl}/credentials/store/system/domain/_/createCredentials' \\
         --user '${jenkinsUser}:${jenkinsToken}' \\
         -H 'Content-Type: application/json' \\
         -H 'Jenkins-Crumb: ${crumb}' \\
         --data @${payloadFile}
    """

    echo "✅ Kubeconfig registered as Jenkins file credential with ID: ${credId}"

    return // safe return
}

return this
