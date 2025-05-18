def manageTerraform(String action) {
    def cloud = env.CLOUD_PROVIDER?.toLowerCase()
    def tfAction = (action == 'destroy') ? 'destroy' : 'apply'

    // Map cloud provider to folder
    def folderMap = [
        'aws'  : 'Terraform/AWS/EKS',
        'azure': 'Terraform/Azure/AKS',
        'gcp'  : 'Terraform/GCP/GKE'
    ]

    if (!folderMap.containsKey(cloud)) {
        error "Unsupported or undefined CLOUD_PROVIDER: '${cloud}'. Must be one of: aws, azure, gcp"
    }

    def terraformDir = "${env.WORKSPACE}/${folderMap[cloud]}"

    if (!fileExists(terraformDir)) {
        error "Terraform directory '${terraformDir}' does not exist!"
    }

    dir(terraformDir) {
        echo "Initializing Terraform in ${terraformDir}"
        sh "terraform init -upgrade"
        sh "terraform ${tfAction} -auto-approve"
    }
}

return this
