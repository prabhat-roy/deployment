def manageKubernetes(String action) {
    def cloud = env.CLOUD_PROVIDER?.toLowerCase()

    if (!cloud) error "❌ CLOUD_PROVIDER environment variable is not set!"
    if (!(action in ['create', 'destroy'])) error "❌ Invalid action '${action}'. Allowed: create, destroy"

    def tfAction = (action == 'destroy') ? 'destroy' : 'apply'
    def terraformDir
    def terraformVars = []
    def validateTerraform = true

    switch (cloud) {
        case 'aws':
            if (!env.AWS_REGION) error "❌ AWS_REGION environment variable is not set!"
            terraformDir = 'Terraform/AWS/EKS'
            terraformVars = ["-var=region=${env.AWS_REGION}"]
            break

        case 'azure':
            def subId = env.SUBSCRIPTION_ID
            def region = env.AZURE_REGION
            def group = env.RESOURCE_GROUP

            if (!subId || !region || !group)
                error "❌ Missing required Azure env variables: SUBSCRIPTION_ID, AZURE_REGION, RESOURCE_GROUP"

            terraformDir = 'Terraform/Azure/AKS'
            terraformVars = [
                "-var=subscription_id=${subId}",
                "-var=azure_region=${region}",
                "-var=resource_group=${group}"
            ]
            break

        case 'gcp':
            def project = env.GOOGLE_PROJECT
            def region = env.GOOGLE_REGION

            if (!project || !region)
                error "❌ Missing required GCP env variables: GOOGLE_PROJECT, GOOGLE_REGION"

            terraformDir = 'Terraform/GCP/GKE'
            terraformVars = [
                "-var=project_id=${project}",
                "-var=region=${region}"
            ]
            break

        default:
            error "❌ Unsupported CLOUD_PROVIDER: '${cloud}'. Supported: aws, azure, gcp"
    }

    dir(terraformDir) {
        echo "📁 Entering Terraform directory: ${terraformDir}"

        sh "terraform init -upgrade"

        if (cloud == 'azure') {
            echo "🧹 Running terraform fmt and validate for Azure..."
            sh "terraform fmt -recursive"
            sh "terraform validate"
        }

        // Check existing resources
        def stateOutput = sh(script: "terraform show -json || true", returnStdout: true).trim()
        def stateHasResources = stateOutput.contains('"values"') && !stateOutput.contains('"values": null')

        if (action == 'create') {
            if (stateHasResources) {
                echo "✅ Cluster already exists, skipping creation."
                return
            }

            if (cloud == 'azure') {
                echo "🚀 Creating AKS cluster and custom node pool..."
                sh "terraform apply -auto-approve ${terraformVars.join(' ')} -var=remove_default_pool=false"
                echo "🧵 Deleting default node pool..."
                sh "terraform apply -auto-approve ${terraformVars.join(' ')} -var=remove_default_pool=true"
                echo "✅ Azure cluster ready with custom node pool only."
            } else {
                echo "🚀 Creating cluster using terraform apply..."
                sh "terraform apply -auto-approve ${terraformVars.join(' ')}"
            }
        } else if (action == 'destroy') {
            if (!stateHasResources) {
                echo "✅ No cluster found, skipping destruction."
                return
            }

            if (cloud == 'azure') {
                echo "🔥 Destroying AKS cluster and node pools..."
                sh "terraform destroy -auto-approve ${terraformVars.join(' ')} -var=remove_default_pool=false"
                echo "✅ Azure cluster destroyed."
            } else {
                echo "🔥 Destroying cluster using terraform destroy..."
                sh "terraform destroy -auto-approve ${terraformVars.join(' ')}"
            }
        }
    }
}

return this
