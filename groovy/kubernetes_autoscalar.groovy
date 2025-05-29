def manageAutoscaler(String action) {
    def props = readProperties file: 'Jenkins.env'

    env.CLOUD_PROVIDER = props['CLOUD_PROVIDER']
    env.AWS_REGION = props['AWS_REGION']
    env.AZURE_REGION = props['AZURE_REGION']
    env.GCP_REGION = props['GCP_REGION']

    def cloud = env.CLOUD_PROVIDER?.toLowerCase()
    if (!cloud) error "❌ CLOUD_PROVIDER environment variable is not set!"
    if (!(action in ['create', 'destroy'])) error "❌ Invalid action '${action}'. Allowed: create, destroy"

    def terraformDir
    def terraformVars = []

    switch (cloud) {
        case 'aws':
            if (!env.AWS_REGION) error "❌ AWS_REGION environment variable is not set!"
            terraformDir = 'Terraform/AWS/Karpenter'
            terraformVars = ["-var=aws_region=${env.AWS_REGION}"]
            break

        case 'azure':
            if (!env.AZURE_REGION) error "❌ AZURE_REGION environment variable is not set!"
            terraformDir = 'Terraform/Azure/Autoscaler'
            terraformVars = ["-var=azure_region=${env.AZURE_REGION}"]
            break

        case 'gcp':
            if (!env.GCP_REGION) error "❌ GCP_REGION environment variable is not set!"
            terraformDir = 'Terraform/GCP/Autoscaler'
            terraformVars = ["-var=gcp_region=${env.GCP_REGION}"]
            break

        default:
            error "❌ Unsupported CLOUD_PROVIDER: '${cloud}'. Supported: aws, azure, gcp"
    }

    dir(terraformDir) {
        echo "📁 Entering Terraform directory: ${terraformDir}"

        sh "terraform init -input=false"

        def stateOutput = sh(script: "terraform show -json || true", returnStdout: true).trim()
        def stateHasResources = stateOutput.contains('"values"') && !stateOutput.contains('"values": null')

        if (action == 'create') {
            if (stateHasResources) {
                echo "✅ Autoscaler resources already exist, skipping creation."
                return
            }

            echo "🚀 Creating autoscaler resources..."
            sh "terraform apply -auto-approve ${terraformVars.join(' ')}"

        } else if (action == 'destroy') {
            if (!stateHasResources) {
                echo "✅ No autoscaler resources found, skipping destruction."
                return
            }

            echo "🔥 Destroying autoscaler resources..."
            sh "terraform destroy -auto-approve ${terraformVars.join(' ')}"
        }
    }
}

return this
