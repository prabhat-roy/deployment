def manageRepository(String action = 'create') {
    // Load required environment variables from Jenkins.env
    def props = readProperties file: 'Jenkins.env'

    env.SERVICES = props['SERVICES']
    env.CLOUD_PROVIDER = props['CLOUD_PROVIDER']
    env.AWS_REGION = props['AWS_REGION']
    env.AZURE_REGION = props['AZURE_REGION']
    env.GCP_REGION = props['GCP_REGION']

    def cloud = env.CLOUD_PROVIDER?.toLowerCase()
    def servicesEnv = env.SERVICES

    if (!cloud) error "❌ CLOUD_PROVIDER environment variable is not set!"
    if (!servicesEnv) error "❌ SERVICES environment variable is not set!"
    if (!(action in ['create', 'destroy'])) error "❌ Unknown action: '${action}'. Allowed: create, destroy"

    def servicesArray = servicesEnv.split(',').collect { it.trim() }
    def terraformVarList = '[' + servicesArray.collect { "\"${it}\"" }.join(', ') + ']'

    echo "🔧 Action: ${action.toUpperCase()} on cloud provider: ${cloud.toUpperCase()}"
    echo "📦 Microservices: ${servicesArray}"

    def terraformDir
    def extraVars

    switch (cloud) {
        case 'aws':
            if (!env.AWS_REGION) error "❌ AWS_REGION environment variable is not set!"
            terraformDir = 'Terraform/AWS/ECR'
            extraVars = """
                ecr_repo_names = ${terraformVarList}
                aws_region     = "${env.AWS_REGION}"
            """
            break
        case 'azure':
            if (!env.AZURE_REGION) error "❌ AZURE_REGION environment variable is not set!"
            terraformDir = 'Terraform/Azure/ACR'
            extraVars = """
                acr_repo_names = ${terraformVarList}
                azure_region   = "${env.AZURE_REGION}"
            """
            break
        case 'gcp':
            if (!env.GCP_REGION) error "❌ GCP_REGION environment variable is not set!"
            terraformDir = 'Terraform/GCP/GAR'
            extraVars = """
                gar_repo_names = ${terraformVarList}
                gcp_region     = "${env.GCP_REGION}"
            """
            break
        default:
            error "❌ Unsupported CLOUD_PROVIDER: '${cloud}'. Supported: aws, azure, gcp"
    }

    // Write terraform.tfvars
    writeFile file: "${terraformDir}/terraform.tfvars", text: extraVars.trim()

    dir(terraformDir) {
        sh "terraform init -input=false"
        sh "terraform plan -var-file=terraform.tfvars"

        if (action == 'create') {
            sh "terraform apply -auto-approve -var-file=terraform.tfvars"
        } else {
            sh "terraform destroy -auto-approve -var-file=terraform.tfvars"
        }
    }
}

def createRepo() {
    manageRepository('create')
}

def removeRepo() {
    manageRepository('destroy')
}

return this
