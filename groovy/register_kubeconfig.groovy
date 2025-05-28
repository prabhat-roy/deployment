import groovy.json.JsonOutput
import java.util.Base64

def getCrumb(String jenkinsUrl, String user, String token) {
    return sh(
        script: "curl -s --user '${user}:${token}' '${jenkinsUrl}/crumbIssuer/api/json' | jq -r .crumb",
        returnStdout: true
    ).trim()
}

def getUserToken(String credId) {
    def result = ""
    withCredentials([usernamePassword(credentialsId: credId, usernameVariable: 'USER', passwordVariable: 'TOKEN')]) {
        result = "${env.USER}:${env.TOKEN}"
    }
    return result
}

def registerKubeconfig() {
    try {
        def props = readProperties file: 'Jenkins.env'

        def cloud = props['CLOUD_PROVIDER']?.toLowerCase()
        def jenkinsUrl = props['JENKINS_URL']
        def jenkinsCreds = props['JENKINS_CREDS_ID']

        if (!cloud) {
            echo "❌ CLOUD_PROVIDER is not defined"
            return
        }
        if (!jenkinsUrl) {
            echo "❌ JENKINS_URL is not defined"
            return
        }
        if (!jenkinsCreds) {
            echo "❌ JENKINS_CREDS_ID is not defined"
            return
        }

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

        // Check if credential already exists
        def existsCode = sh(
            script: """curl -s -o /dev/null -w "%{http_code}" -u '${jenkinsUser}:${jenkinsToken}' \
'${jenkinsUrl}/credentials/store/system/domain/_/credential/${credId}/api/json'""",
            returnStdout: true
        ).trim()

        if (existsCode == "200") {
            echo "✅ Credential '${credId}' already exists, skipping creation."
            return
        }

        // Copy kubeconfig to workspace
        sh "cp ~/.kube/config ${env.WORKSPACE}/kubeconfig"

        // Read kubeconfig as base64 string
        def kubeconfigBase64 = sh(
            script: "base64 -w0 ${env.WORKSPACE}/kubeconfig",
            returnStdout: true
        ).trim()

        // Decode base64 to bytes
        byte[] decodedBytes = Base64.decoder.decode(kubeconfigBase64)

        // Convert bytes to list of integers
        def bytesList = decodedBytes.collect { it & 0xFF }

        // Build JSON payload with correct structure
        def payloadMap = [
            credentials: [
                scope      : "GLOBAL",
                id         : credId,
                description: "Kubeconfig for ${cloud} cluster",
                "\$class"  : "org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl",
                fileName   : "config",
                secretBytes: [
                    "\$class": "org.jenkinsci.plugins.plaincredentials.impl.SecretBytes",
                    bytes   : bytesList
                ]
            ]
        ]

        def payloadFile = "${env.WORKSPACE}/kubeconfig-payload.json"
        writeFile file: payloadFile, text: JsonOutput.toJson(payloadMap)

        // Get Jenkins crumb for CSRF protection
        def crumb = getCrumb(jenkinsUrl, jenkinsUser, jenkinsToken)

        // Send POST request to create credential
        sh """
        curl -s -X POST '${jenkinsUrl}/credentials/store/system/domain/_/createCredentials' \\
             --user '${jenkinsUser}:${jenkinsToken}' \\
             -H 'Content-Type: application/json' \\
             -H 'Jenkins-Crumb: ${crumb}' \\
             --data @${payloadFile}
        """

        echo "✅ Kubeconfig registered as Jenkins file credential with ID: ${credId}"

    } catch (Exception e) {
        echo "❌ Failed to register kubeconfig credential: ${e.getMessage()}"
    }
}

return this
