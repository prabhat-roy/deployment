def scanAndArchiveImages() {
    echo "📥 Pulling latest Trivy image..."
    sh 'docker pull aquasec/trivy:latest'

    def buildNumber = env.BUILD_NUMBER
    def dockerServices = env.DOCKER_SERVICES

    if (!buildNumber) {
        error "❌ BUILD_NUMBER environment variable is missing!"
    }
    if (!dockerServices) {
        error "❌ DOCKER_SERVICES environment variable is missing!"
    }

    def services = dockerServices.split(",").collect { it.trim() }.findAll { it }

    if (services.isEmpty()) {
        error "❌ No valid services found in DOCKER_SERVICES!"
    }

    sh 'mkdir -p trivy-reports'

    services.each { service ->
        def imageTag = "${service}:${buildNumber}"
        def reportFile = "trivy-reports/${service}.txt"

        echo "🔍 Scanning image: ${imageTag}"
        sh """
            docker run --rm \
              -v /var/run/docker.sock:/var/run/docker.sock \
              -v \$PWD:/root/.cache/ \
              aquasec/trivy:latest image \
              --no-progress \
              --severity CRITICAL,HIGH \
              --format table \
              -o ${reportFile} \
              ${imageTag} || echo "⚠️  Vulnerabilities found in ${imageTag}, but continuing."
        """
    }

    echo "📦 Archiving Trivy reports..."
    archiveArtifacts artifacts: 'trivy-reports/*.txt', allowEmptyArchive: true

    echo "✅ Trivy scan and archive complete."
}

return this
