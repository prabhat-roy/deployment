def scanAndArchiveReports() {
    echo "📥 Pulling latest cnspec Docker image..."
    sh 'docker pull aquasecurity/cnspec:latest'

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

    sh 'mkdir -p cnspec-reports'

    services.each { service ->
        def imageTag = "${service}:${buildNumber}"
        def containerName = "cnspec-${service}-${buildNumber}".replaceAll("[^a-zA-Z0-9_-]", "-")
        def reportPath = "cnspec-reports/${service}.json"

        echo "🚀 Starting container from image: ${imageTag}"
        sh """
            docker run -d --rm --name ${containerName} ${imageTag} tail -f /dev/null || echo '⚠️ Failed to start container'
        """

        echo "🔍 Running cnspec scan on container: ${containerName}"
        sh """
            docker run --rm \
              -v /var/run/docker.sock:/var/run/docker.sock \
              aquasecurity/cnspec:latest \
              scan docker://${containerName} --output json > ${reportPath} || echo '⚠️ cnspec scan failed for ${imageTag}'
        """

        echo "🧹 Stopping and removing container: ${containerName}"
        sh "docker rm -f ${containerName} || true"

        // Fallback for missing report
        if (!fileExists(reportPath)) {
            echo "⚠️  Creating dummy report: ${reportPath}"
            writeFile file: reportPath, text: "No report generated for ${imageTag}. Scan may have failed."
        }
    }

    echo "📁 Listing cnspec reports..."
    sh "ls -lh cnspec-reports"

    echo "📦 Archiving cnspec reports..."
    archiveArtifacts artifacts: 'cnspec-reports/*.json', allowEmptyArchive: false

    echo "✅ cnspec scan and archive complete."
}

return this
