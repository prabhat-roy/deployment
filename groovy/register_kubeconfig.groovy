import groovy.json.JsonOutput

def registerKubeconfig(String action) {
    def props = readProperties file: 'Jenkins.env'

    def cloud = props['CLOUD_PROVIDER']?.toLowerCase()
    def jenkinsUrl = props['JENKINS_URL']
    def jenkinsCreds = props['JENKINS_CREDS_ID']

    if (!cloud) error "❌ CLOUD_PROVIDER is not defined"
    if (!jenkinsUrl) error "❌ JENKINS_URL is not defined"
    if (!jenkinsCreds) error "❌ JENKINS_CREDS_ID is not defined"
    if (!(action in ['create', 'destroy'])) error "❌ Invalid action '${action}'. Use 'create' or 'destroy'"

    if (!jenkinsCreds.contains(":")) {
        error "❌ JENKINS_CREDS_ID must be in format 'username:apitoken'"
    }

    def (jenkinsUser, jenkinsToken) = jenkinsCreds.split(":", 2).collect { it.trim() }
    def credId = "kubeconfig-credential"

    // Check if credential exists
    def exists = (sh(script: """
        curl -s -o /dev/null -w "%{http_code}" -u '${jenkinsUser}:${jenkinsToken}' \
        '${jenkinsUrl}/credentials/store/system/domain/_/credential/${credId}/api/json'
    """, returnStdout: true).trim() == "200")

    if (action == 'destroy') {
        if (!exists) {
            echo "⚠️ Credential '${credId}' not found, skipping deletion."
            return
        }

        echo "🔥 Deleting Jenkins credential '${credId}'..."
        sh script: """
            curl -s -X POST '${jenkinsUrl}/credentials/store/system/domain/_/credential/${credId}/doDelete' \
            --user '${jenkinsUser}:${jenkinsToken}'
        """
        echo "✅ Credential '${credId}' deleted."
        return
    }

    if (exists) {
        echo "✅ Credential '${credId}' already exists, skipping creation."
        return
    }

    // --- Create kubeconfig depending on cloud provider ---
    switch (cloud) {
        case 'aws':
            if (!props['AWS_REGION']) error "❌ AWS_REGION not set"
            def clusterName = props['CLUSTER_NAME'] ?: 'eks-cluster'
            sh "aws eks update-kubeconfig --region ${props['AWS_REGION']} --name ${clusterName}"
            break
        case 'azure':
            if (!props['RESOURCE_GROUP']) error "❌ RESOURCE_GROUP not set"
            def clusterName = props['CLUSTER_NAME'] ?: 'aks-cluster'
            sh "az aks get-credentials --resource-group ${props['RESOURCE_GROUP']} --name ${clusterName} --overwrite-existing"
            break
        case 'gcp':
            if (!props['GOOGLE_PROJECT'] || !props['GOOGLE_REGION']) {
                error "❌ GOOGLE_PROJECT and GOOGLE_REGION must be set"
            }
            def clusterName = props['CLUSTER_NAME'] ?: 'gke-cluster'
            sh "gcloud container clusters get-credentials ${clusterName} --region ${props['GOOGLE_REGION']} --project ${props['GOOGLE_PROJECT']}"
            break
        default:
            error "❌ Unsupported CLOUD_PROVIDER: ${cloud}"
    }

    def kubeconfigPath = "${env.WORKSPACE}/kubeconfig"
    sh "cp ~/.kube/config ${kubeconfigPath}"

    def kubeconfigBase64 = sh(
        script: "base64 ${kubeconfigPath} | tr -d '\\n'",
        returnStdout: true
    ).trim()

    def payloadMap = [
        credentials: [
            scope      : "GLOBAL",
            id         : credId,
            description: "Kubeconfig for ${cloud} cluster",
            '$class'   : "org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl",
            fileName   : "config",
            secretBytes: kubeconfigBase64
        ]
    ]

    def payloadFile = "${env.WORKSPACE}/kubeconfig-payload.json"
    writeFile file: payloadFile, text: JsonOutput.toJson(payloadMap)

    echo "🔐 Creating Jenkins credential '${credId}'..."
    sh script: """
        curl -s -X POST '${jenkinsUrl}/credentials/store/system/domain/_/createCredentials' \
        --user '${jenkinsUser}:${jenkinsToken}' \
        -H 'Content-Type: application/json' \
        -d @${payloadFile}
    """
    echo "✅ Kubeconfig registered as Jenkins file credential with ID: ${credId}"
}

return this
