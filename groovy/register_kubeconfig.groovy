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

    // Check if credential already exists
    def credCheckCmd = """
        curl -s -u '${jenkinsUser}:${jenkinsToken}' '${jenkinsUrl}/credentials/store/system/domain/_/credential/${credId}/api/json'
    """
    def exists = (sh(script: credCheckCmd, returnStatus: true) == 0)

    if (action == 'destroy') {
        if (!exists) {
            echo "⚠️ Credential '${credId}' not found, skipping deletion."
            return
        }

        def deleteCmd = """
            curl -s -X POST '${jenkinsUrl}/credentials/store/system/domain/_/credential/${credId}/doDelete' \\
            --user '${jenkinsUser}:${jenkinsToken}'
        """
        echo "🔥 Deleting Jenkins credential '${credId}'..."
        sh deleteCmd
        echo "✅ Credential '${credId}' deleted."
        return
    }

    // For 'create' only
    if (exists) {
        echo "✅ Credential '${credId}' already exists, skipping creation."
        return
    }

    // Update kubeconfig based on cloud
    switch (cloud) {
        case 'aws':
            if (!props['AWS_REGION']) error "❌ AWS_REGION not set"
            sh "aws eks update-kubeconfig --region ${props['AWS_REGION']} --name eks-cluster"
            break
        case 'azure':
            if (!props['RESOURCE_GROUP']) error "❌ RESOURCE_GROUP not set"
            sh "az aks get-credentials --resource-group ${props['RESOURCE_GROUP']} --name aks-cluster --overwrite-existing"
            break
        case 'gcp':
            if (!props['GOOGLE_PROJECT']) error "❌ GOOGLE_PROJECT not set"
            sh "gcloud container clusters get-credentials gke-cluster --region ${props['GOOGLE_REGION']} --project ${props['GOOGLE_PROJECT']}"
            break
        default:
            error "❌ Unsupported CLOUD_PROVIDER: ${cloud}"
    }

    // Copy kubeconfig and encode it
    def kubeconfigPath = "${env.WORKSPACE}/kubeconfig"
    sh "cp ~/.kube/config ${kubeconfigPath}"

    def kubeconfigBase64 = sh(
        script: "base64 ${kubeconfigPath} | tr -d '\\n'",
        returnStdout: true
    ).trim()

    // Create credential JSON payload
    def payload = JsonOutput.toJson([
        credentials: [
            scope      : "GLOBAL",
            id         : credId,
            description: "Kubeconfig for ${cloud} cluster",
            $class     : "org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl",
            fileName   : "config",
            secretBytes: kubeconfigBase64
        ]
    ])

    def createCmd = """
        curl -s -X POST '${jenkinsUrl}/credentials/store/system/domain/_/createCredentials' \\
        --user '${jenkinsUser}:${jenkinsToken}' \\
        -H 'Content-Type: application/json' \\
        -d '${payload}'
    """

    echo "🔐 Creating Jenkins credential '${credId}'..."
    sh createCmd
    echo "✅ Kubeconfig registered as Jenkins file credential with ID: ${credId}"
}

return this
