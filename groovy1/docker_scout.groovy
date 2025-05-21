def scanAndArchiveReports() {
    echo "📥 Pulling latest Docker Scout image..."

    // Ensure Docker Scout is installed or pull the latest Docker image
    sh 'docker pull ghcr.io/docker/scout:latest'

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

    sh 'mkdir -p docker-scout-reports'

    services.each { service ->
        def imageTag = "${service}:${buildNumber}"

        def scanReport = "docker-scout-reports/${service}-scan.txt"

        echo "🔍 Scanning image with Docker Scout: ${imageTag}"

        // Run Docker Scout scan
        sh """
            docker run --rm \
              -v /var/run/docker.sock:/var/run/docker.sock \
              ghcr.io/docker/scout:latest scan ${imageTag} > ${scanReport} || echo '⚠️  Scan failed for ${imageTag}'
        """

        // Fallback if any file is missing
        if (!fileExists(scanReport)) {
            echo "⚠️  Creating dummy report: ${scanReport}"
            writeFile file: scanReport, text: "No report generated for ${imageTag}. Scan may have failed."
        }
    }

    echo "📁 Listing Docker Scout reports..."
    sh "ls -lh docker-scout-reports"

    echo "📦 Archiving Docker Scout reports..."
    archiveArtifacts artifacts: 'docker-scout-reports/*.{txt}', allowEmptyArchive: false

    echo "✅ Docker Scout scan and report archive complete."
}

return this
