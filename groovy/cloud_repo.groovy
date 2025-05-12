def createCloudRepo(String action) {
    def cloud = env.CLOUD_PROVIDER?.toLowerCase()

    if (!cloud) {
        error "❌ CLOUD_PROVIDER environment variable is not set!"
    }

    if (action != 'create' && action != 'destroy') {
        error "❌ Unknown action: '${action}'. Allowed: create, destroy"
    }

    echo "🔧 Action: ${action.toUpperCase()} for cloud provider: ${cloud.toUpperCase()}"

    switch (cloud) {
        case "aws":
            echo "🚀 Running AWS ECR Script..."
            sh """
                chmod +x shell_script/ecr.sh
                shell_script/ecr.sh ${action}
            """
            break

        case "azure":
            echo "🚀 Running Azure ACR Script..."
            sh """
                chmod +x shell_script/acr.sh
                shell_script/acr.sh ${action}
            """
            break

        case "gcp":
            echo "🚀 Running GCP GAR Script..."
            sh """
                chmod +x shell_script/gar.sh
                shell_script/gar.sh ${action}
            """
            break

        default:
            error "❌ Unsupported CLOUD_PROVIDER: '${cloud}'. Supported values are: aws, azure, gcp"
    }
}

return this
