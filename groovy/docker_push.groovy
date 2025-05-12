def pushToCloudRegistry = {
    def cloudEnv = env.CLOUD_PROVIDER?.toLowerCase()

    if (!cloudEnv) {
        error "[ERROR] CLOUD_PROVIDER environment variable not set. Exiting."
    }

    def dockerServices = env.DOCKER_SERVICES?.split(',') ?: []
    if (dockerServices.isEmpty()) {
        error "[ERROR] No Docker services found in DOCKER_SERVICES environment variable."
    }

    switch (cloudEnv) {
        case 'aws':
            def awsAccountId = env.AWS_ACCOUNT_ID
            def awsRegion = env.AWS_REGION ?: "us-east-1"
            def registryUri = "${awsAccountId}.dkr.ecr.${awsRegion}.amazonaws.com"

            echo "[INFO] Logging into AWS ECR..."
            sh "aws ecr get-login-password --region ${awsRegion} | docker login --username AWS --password-stdin ${registryUri}"

            dockerServices.each { svc ->
                def (image, tag) = svc.tokenize(':')
                def repoName = image
                def newTag = "${registryUri}/${repoName}:${BUILD_NUMBER}"

                echo "[INFO] Ensuring ECR repository exists: ${repoName}"
                def repoExists = sh(script: "aws ecr describe-repositories --repository-names ${repoName} --region ${awsRegion}", returnStatus: true) == 0
                if (!repoExists) {
                    echo "[INFO] Creating ECR repository: ${repoName}"
                    sh "aws ecr create-repository --repository-name ${repoName} --region ${awsRegion} >/dev/null"
                }

                echo "[INFO] Tagging and pushing ${image}:${tag} to ${newTag}"
                sh "docker tag ${image}:${tag} ${newTag}"
                sh "docker push ${newTag}"
                sh "docker rmi ${newTag}"
            }
            break

        case 'azure':
            def acrLoginServer = env.ACR_LOGIN_SERVER
            if (!acrLoginServer) error "[ERROR] ACR_LOGIN_SERVER not defined"

            echo "[INFO] Logging into Azure ACR..."
            sh "az acr login --name ${acrLoginServer}"

            dockerServices.each { svc ->
                def (image, tag) = svc.tokenize(':')
                def newTag = "${acrLoginServer}/${image}:${BUILD_NUMBER}"

                echo "[INFO] Tagging and pushing ${image}:${tag} to ${newTag}"
                sh "docker tag ${image}:${tag} ${newTag}"
                sh "docker push ${newTag}"
                sh "docker rmi ${newTag}"
            }
            break

        case 'gcp':
            def gcrRegion = "gcr.io"
            def gcpProject = env.GCP_PROJECT_ID
            if (!gcpProject) error "[ERROR] GCP_PROJECT_ID not defined"

            echo "[INFO] Configuring Docker for GCR..."
            sh "gcloud auth configure-docker ${gcrRegion} -q"

            dockerServices.each { svc ->
                def (image, tag) = svc.tokenize(':')
                def newTag = "${gcrRegion}/${gcpProject}/${image}:${BUILD_NUMBER}"

                echo "[INFO] Tagging and pushing ${image}:${tag} to ${newTag}"
                sh "docker tag ${image}:${tag} ${newTag}"
                sh "docker push ${newTag}"
                sh "docker rmi ${newTag}"
            }
            break

        default:
            error "[ERROR] Unknown or unsupported CLOUD_PROVIDER: ${cloudEnv}"
    }

    echo "[INFO] Docker image push complete."
}

return [pushToCloudRegistry: pushToCloudRegistry]
