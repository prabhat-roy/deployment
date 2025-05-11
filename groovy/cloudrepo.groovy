def createCloudRepo() {
    def cloud = env.CLOUD_PROVIDER?.toLowerCase()

    if (!cloud) {
        error "❌ CLOUD_PROVIDER environment variable is not set!"
    }

    switch (cloud) {
        case "aws":
            echo "🚀 Creating AWS ECR Repositories..."
            sh '''
                chmod +x shell_script/generate-ecr.sh
                shell_script/generate-ecr.sh
            '''
            break

        case "azure":
            echo "🚀 Creating Azure ACR Repositories..."
            sh '''
                chmod +x shell_script/generate-acr.sh
                shell_script/generate-acr.sh
            '''
            break

        case "gcp":
            echo "🚀 Creating GCP Artifact Registry Repositories..."
            sh '''
                chmod +x shell_script/generate-gcr.sh
                shell_script/generate-gcr.sh
            '''
            break

        default:
            error "❌ Unsupported CLOUD_PROVIDER: '${cloud}'. Supported values are: aws, azure, gcp"
    }
}

return this
