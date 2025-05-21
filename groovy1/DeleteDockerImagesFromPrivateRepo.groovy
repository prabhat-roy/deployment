def deleteDockerImagesFromPrivateRepo = { imageName ->
    // Detect the cloud environment (AWS, Azure, GCP)
    def cloudEnv = ''
    try {
        cloudEnv = sh(script: 'curl -s http://169.254.169.254/latest/meta-data/', returnStdout: true).trim()
    } catch (Exception e) {
        echo "[WARNING] Unable to detect cloud environment using metadata service. Falling back to environment variables."
    }

    // Fallback cloud detection using environment variables
    if (!cloudEnv) {
        if (env.AWS_DEFAULT_REGION || env.AWS_REGION) {
            cloudEnv = 'aws'
        } else if (env.GOOGLE_CLOUD_PROJECT) {
            cloudEnv = 'gcp'
        } else if (env.AZURE_HTTP_USER_AGENT) {
            cloudEnv = 'azure'
        }
    }

    // Cloud environment checks and deleting images
    if (cloudEnv.contains('aws')) {
        echo "[INFO] Detected AWS environment. Deleting image from AWS ECR."
        
        // AWS - Deleting from ECR
        def ecrRepos = env.AWS_ECR_REPOS.split(",") ?: []
        def ecrRegion = env.AWS_REGION ?: "us-east-1" // Default to us-east-1 if not specified
        def awsAccountId = env.AWS_ACCOUNT_ID ?: "your-aws-account-id"
        
        // AWS ECR login
        try {
            sh "aws ecr get-login-password --region ${ecrRegion} | docker login --username AWS --password-stdin ${awsAccountId}.dkr.ecr.${ecrRegion}.amazonaws.com"
        } catch (Exception e) {
            error "[ERROR] Failed to login to AWS ECR. Cloud detected: ${cloudEnv}"
        }

        // Delete Docker image from AWS ECR for each repository
        ecrRepos.each { ecrRepo ->
            try {
                sh "aws ecr batch-delete-image --repository-name ${ecrRepo} --image-ids imageTag=${imageName} --region ${ecrRegion}"
                echo "[INFO] Image deleted from AWS ECR repo ${ecrRepo}."
            } catch (Exception e) {
                echo "[WARNING] Failed to delete image from AWS ECR repo ${ecrRepo}. Cloud detected: ${cloudEnv}"
            }
        }

    } else if (cloudEnv.contains('azure')) {
        echo "[INFO] Detected Azure environment. Deleting image from Azure ACR."
        
        // Azure - Deleting from ACR
        def acrRepos = env.ACR_REPOS.split(",") ?: []
        def acrLoginServer = env.ACR_LOGIN_SERVER ?: "your-acr-name.azurecr.io"
        
        // Azure login
        try {
            sh "az acr login --name ${acrLoginServer}"
        } catch (Exception e) {
            error "[ERROR] Failed to login to Azure ACR. Cloud detected: ${cloudEnv}"
        }

        // Delete Docker image from Azure ACR for each repository
        acrRepos.each { acrRepo ->
            try {
                sh "az acr repository delete --name ${acrLoginServer} --repository ${acrRepo} --tag ${imageName} --yes"
                echo "[INFO] Image deleted from Azure ACR repo ${acrRepo}."
            } catch (Exception e) {
                echo "[WARNING] Failed to delete image from Azure ACR repo ${acrRepo}. Cloud detected: ${cloudEnv}"
            }
        }

    } else if (cloudEnv.contains('googleapis')) {
        echo "[INFO] Detected GCP environment. Deleting image from Google GCR."
        
        // GCP - Deleting from GCR
        def gcrRepos = env.GCR_REPOS.split(",") ?: []
        def gcrRegion = "gcr.io"
        
        // GCP login
        try {
            sh "gcloud auth configure-docker"
        } catch (Exception e) {
            error "[ERROR] Failed to authenticate with GCP. Cloud detected: ${cloudEnv}"
        }

        // Delete Docker image from GCR for each repository
        gcrRepos.each { gcrRepo ->
            try {
                sh "gcloud container images delete ${gcrRegion}/${gcrRepo}/${imageName} --quiet"
                echo "[INFO] Image deleted from GCR repo ${gcrRepo}."
            } catch (Exception e) {
                echo "[WARNING] Failed to delete image from GCR repo ${gcrRepo}. Cloud detected: ${cloudEnv}"
            }
        }
        
    } else {
        error "[ERROR] Unknown cloud environment. Cloud detected: ${cloudEnv}. Cannot delete Docker image."
    }

    echo "[INFO] Docker image deleted successfully from the cloud registry."
}

return [deleteDockerImagesFromPrivateRepo: deleteDockerImagesFromPrivateRepo]
