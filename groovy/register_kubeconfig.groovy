import groovy.json.JsonOutput

def registerKubeconfig() {
    echo "🚀 Starting Kubernetes credential registration"

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

    echo "🔍 Checking if credential '${credId}' already exists"

    def existsCode = sh(
        script: """curl -s -o /dev/null -w "%{http_code}" -u '${jenkinsUser}:${jenkinsToken}' \
        '${jenkinsUrl}/credentials/store/system/domain/_/credential/${credId}/api/json'""",
        returnStdout: true
    ).trim()

    if (existsCode == "200") {
        echo "✅ Credential '${credId}' already exists, skipping creation."
        return
    }

    echo "📋 Copying kubeconfig file to workspace"
    sh "cp ~/.kube/config ${env.WORKSPACE}/kubeconfig"

    echo "📤 Generating JSON array of raw kubeconfig bytes (avoiding decodeBase64 Groovy restriction)..."
    def bytesJson = sh(
        script: """
            base64 -d ${env.WORKSPACE}/kubeconfig | od -An -t u1 | tr -s ' ' '\\n' | grep -v '^$' | jq -R -s 'split("\\n") | map(select(length > 0) | tonumber)'
        """,
        returnStdout: true
    ).trim()

    echo "Bytes JSON length: ${bytesJson.length()}"
    echo "Bytes JSON snippet: ${bytesJson.take(200)}"

    def byteList = readJSON text: bytesJson

    echo "✔ Parsed byte array length: ${byteList.size()}"

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
                bytes   : byteList
            ]
        ]
    ]

    def payloadFile = "${env.WORKSPACE}/kubeconfig-payload.json"
    def payloadJson = JsonOutput.prettyPrint(JsonOutput.toJson(payloadMap))

    echo "📄 Writing payload JSON to ${payloadFile}"
    writeFile file: payloadFile, text: payloadJson

    echo "🔑 Getting Jenkins crumb for CSRF protection"
    def crumb = sh(
        script: "curl -s --user '${jenkinsUser}:${jenkinsToken}' '${jenkinsUrl}/crumbIssuer/api/json' | jq -r .crumb",
        returnStdout: true
    ).trim()

    echo "📝 Sending credential creation POST request"
    def response = sh(
        script: """
        curl -v -X POST '${jenkinsUrl}/credentials/store/system/domain/_/createCredentials' \\
            --user '${jenkinsUser}:${jenkinsToken}' \\
            -H 'Content-Type: application/json' \\
            -H 'Jenkins-Crumb: ${crumb}' \\
            --data @${payloadFile}
        """,
        returnStdout: true
    ).trim()

    echo "Response: ${response}"

    echo "✅ Kubeconfig registered as Jenkins file credential with ID: ${credId}"

    return true
}

def getUserToken(String credId) {
    def result = ""
    withCredentials([usernamePassword(credentialsId: credId, usernameVariable: 'USER', passwordVariable: 'TOKEN')]) {
        result = "${env.USER}:${env.TOKEN}"
    }
    return result
}

return this
