def createRepo() {
    def action = 'create'
    manageRepo(action)
}

def removeRepo() {
    def action = 'destroy'
    manageRepo(action)
}

private def manageRepo(String action) {
    def cloud = env.CLOUD_PROVIDER?.toLowerCase()
    def servicesEnv = env.SERVICES

    if (!cloud) {
        error "❌ CLOUD_PROVIDER environment variable is not set!"
    }
    if (!servicesEnv) {
        error "❌ SERVICES environment variable is not set!"
    }
    if (action != 'create' && action != 'destroy') {
        error "❌ Unknown action: '${action}'. Allowed: create, destroy"
    }

    // Convert comma separated SERVICES env var to Terraform list format
    def servicesArray = servicesEnv.split(',').collect { it.trim() }
    def terraformList = servicesArray.collect { "\"${it}\"" }.join(", ")
    def terraformVarList = "[${terraformList}]"

    echo "🔧 Action: ${action.toUpperCase()} on cloud provider: ${cloud.toUpperCase()}"
    echo "🔧 Microservices: ${servicesArray}"

    def terraformDir = ''
    def extraVars = ''

    switch (cloud) {
        case 'aws':
            terraformDir = 'Terraform/AWS/ECR'
            extraVars = """
                ecr_repo_names = ${terraformVarList}
                aws_region     = "${env.AWS_REGION ?: 'us-east-1'}"
            """
            break

        case 'azure':
            terraformDir = 'Terraform/Azure/ACR'
            extraVars = """
                acr_repo_names = ${terraformVarList}
                azure_region  = "${env.AZURE_REGION ?: 'eastus'}"
            """
            break

        case 'gcp':
            terraformDir = 'Terraform/GCP/GAR'
            extraVars = """
                gar_repo_names = ${terraformVarList}
                gcp_region     = "${env.GCP_REGION ?: 'us-central1'}"
            """
            break

        default:
            error "❌ Unsupported CLOUD_PROVIDER: '${cloud}'. Supported: aws, azure, gcp"
    }

    // Write terraform.tfvars file with variables
    writeFile file: "${terraformDir}/terraform.tfvars", text: extraVars.trim()

    dir(terraformDir) {
        sh """
            terraform init -input=false
            terraform plan -var-file=terraform.tfvars
        """

        if (action == 'create') {
            sh "terraform apply -auto-approve -var-file=terraform.tfvars"
        } else if (action == 'destroy') {
            sh "terraform destroy -auto-approve -var-file=terraform.tfvars"
        }
    }
}

return this
