import groovy.json.JsonOutput

def registerKubeconfig() {
    def props = readProperties file: 'Jenkins.env'

    def cloud = props['CLOUD_PROVIDER']?.toLowerCase()
    def jenkinsUrl = props['JENKINS_URL']
    def jenkinsCredsId = props['JENKINS_CREDS_ID']

    if (!cloud) error "❌ CLOUD_PROVIDER is not defined"
    if (!jenkinsUrl) error "❌ JENKINS_URL is not defined"
    if (!jenkinsCredsId) error "❌ JENKINS_CREDS_ID is not defined"

    // Load kubeconfig
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

    // Store kubeconfig to temp
    def kubeconfigPath = "${env.WORKSPACE}/kubeconfig"
    sh "cp ~/.kube/config ${kubeconfigPath}"

    def kubeconfigBase64 = sh(script: "base64 -w 0 ${kubeconfigPath}", returnStdout: true).trim()
    def usernamePassword = props['JENKINS_CREDS_ID'].split(':')
    def jenkinsUser = usernamePassword[0].trim()
    def jenkinsToken = usernamePassword[1].trim()

    def payload = JsonOutput.toJson([
        "": "0",
        credentials: [
            scope      : "GLOBAL",
            id         : "kubeconfig-credential",
            description: "Kubeconfig for ${cloud} cluster",
            $class     : "org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl",
            fileName   : "config",
            secretBytes: kubeconfigBase64
        ]
    ])

    def curlCmd = """
        curl -s -X POST "${jenkinsUrl}/credentials/store/system/domain/_/createCredentials" \\
        --user "${jenkinsUser}:${jenkinsToken}" \\
        -H "Content-Type: application/json" \\
        -d '${payload}'
    """

    echo "🔐 Creating Jenkins credential for kubeconfig..."
    sh curlCmd
    echo "✅ Kubeconfig registered as Jenkins file credential with ID: kubeconfig-credential"
}

return this
