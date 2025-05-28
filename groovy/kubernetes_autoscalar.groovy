def manageAutoscalar(String action = 'create', boolean skipIfExists = true) {
    def props = readProperties file: 'Jenkins.env'

    env.CLOUD_PROVIDER = props['CLOUD_PROVIDER']
    env.AWS_REGION = props['AWS_REGION']
    env.AZURE_REGION = props['AZURE_REGION']
    env.GCP_REGION = props['GCP_REGION']

    def cloud = env.CLOUD_PROVIDER?.toLowerCase()
    if (!cloud) error "❌ CLOUD_PROVIDER environment variable is not set!"

    if (!(action in ['create', 'destroy'])) error "❌ Unknown action: '${action}'. Allowed: create, destroy"

    def terraformDir
    def extraVars = ''

    switch(cloud) {
        case 'aws':
            if (!env.AWS_REGION) error "❌ AWS_REGION environment variable is not set!"
            terraformDir = 'Terraform/AWS/Karpenter'
            extraVars = """
                aws_region = "${env.AWS_REGION}"
            """
            break

        case 'azure':
            if (!env.AZURE_REGION) error "❌ AZURE_REGION environment variable is not set!"
            terraformDir = 'Terraform/Azure/Autoscaler'
            extraVars = """
                azure_region = "${env.AZURE_REGION}"
            """
            break

        case 'gcp':
            if (!env.GCP_REGION) error "❌ GCP_REGION environment variable is not set!"
            terraformDir = 'Terraform/GCP/Autoscaler'
            extraVars = """
                gcp_region = "${env.GCP_REGION}"
            """
            break

        default:
            error "❌ Unsupported CLOUD_PROVIDER: '${cloud}'. Supported: aws, azure, gcp"
    }

    writeFile file: "${terraformDir}/terraform.tfvars", text: extraVars.trim()

    dir(terraformDir) {
        echo "📁 Entering Terraform directory: ${terraformDir}"

        sh "terraform init -input=false"

        def stateCheck = sh(script: "terraform state list || true", returnStdout: true).trim()
        def resourcesExist = stateCheck ? true : false

        if (action == 'create') {
            if (skipIfExists && resourcesExist) {
                echo "✅ Skipping creation. Resources already exist in Terraform state."
                return
            }
            echo "🚀 Creating K8s autoscaler resources..."
            sh "terraform plan -var-file=terraform.tfvars"
            sh "terraform apply -auto-approve -var-file=terraform.tfvars"
        } else if (action == 'destroy') {
            if (!resourcesExist) {
                error "❌ No resources found in Terraform state. Cannot destroy."
            }
            echo "🔥 Destroying K8s autoscaler resources..."
            sh "terraform plan -destroy -var-file=terraform.tfvars"
            sh "terraform destroy -auto-approve -var-file=terraform.tfvars"
        }
    }
}

return this
