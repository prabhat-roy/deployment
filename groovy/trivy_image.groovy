def scanAndArchiveImages(String envFile = 'Jenkins.env') {
    echo "📥 Pulling latest Trivy image..."
    sh 'docker pull aquasec/trivy:latest'

    if (!fileExists(envFile)) {
        error "❌ ${envFile} not found!"
    }

    def envVars = readFile(envFile).readLines()
    def buildNumber = envVars.find { it.startsWith("BUILD_NUMBER=") }?.split("=")[1]
    def dockerServices = envVars.find { it.startsWith("DOCKER_SERVICES=") }?.split("=")[1]

    if (!buildNumber || !dockerServices) {
        error "❌ BUILD_NUMBER or DOCKER_SERVICES missing in ${envFile}"
    }

    def services = dockerServices.split(",")
    sh 'mkdir -p trivy-reports'

    services.each { service ->
        def imageTag = "${service}:${buildNumber}"
        def reportFile = "trivy-reports/${service}.txt"

        echo "🔍 Scanning ${imageTag}..."
        sh """
            docker run --rm \
              -v /var/run/docker.sock:/var/run/docker.sock \
              -v \$PWD:/root/.cache/ \
              aquasec/trivy:latest image \
              --no-progress \
              --severity CRITICAL,HIGH \
              --format table \
              -o ${reportFile} \
              ${imageTag} || echo "⚠️  Issues found in ${imageTag}"
        """
    }

    echo "📦 Archiving Trivy reports..."
    archiveArtifacts artifacts: 'trivy-reports/*.txt', allowEmptyArchive: true

    echo "✅ Trivy scan and archive complete."
}

return this
