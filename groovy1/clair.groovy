def scanAndArchiveReports() {
    echo "📥 Starting Clair vulnerability scan using klar..."

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

    sh 'mkdir -p clair-reports'

    services.each { service ->
        def imageTag = "${service}:${buildNumber}"
        def reportFile = "clair-reports/${service}.txt"

        echo "🔍 Scanning image with Clair (via klar): ${imageTag}"

        sh """
            docker pull ${imageTag} || echo '⚠️ Failed to pull ${imageTag}'
            klar ${imageTag} > ${reportFile} 2>&1 || echo '⚠️ Scan failed for ${imageTag}'
        """

        // Fallback in case scan fails and file doesn't exist
        if (!fileExists(reportFile)) {
            echo "⚠️  Creating dummy report: ${reportFile}"
            writeFile file: reportFile, text: "No report generated for ${imageTag}. Scan may have failed."
        }
    }

    echo "📁 Listing Clair reports..."
    sh "ls -lh clair-reports"

    echo "📦 Archiving Clair reports..."
    archiveArtifacts artifacts: 'clair-reports/*.txt', allowEmptyArchive: false

    echo "✅ Clair scan and archive complete."
}

return this
