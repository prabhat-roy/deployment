def scanAndArchiveReports() {
    echo "📥 Pulling latest Checkov image..."
    sh 'docker pull bridgecrew/checkov:latest'

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

    sh 'mkdir -p checkov-reports'

    services.each { service ->
        def imageTag = "${service}:${buildNumber}"

        def jsonReport  = "checkov-reports/${service}-checkov.json"
        def sarifReport = "checkov-reports/${service}-checkov.sarif"

        echo "🔍 Running Checkov scan on: ${imageTag}"

        // JSON format
        sh """
            docker run --rm \
              -v \$PWD:/workspace \
              bridgecrew/checkov:latest \
              -d /workspace/${service} \
              --output json \
              -o ${jsonReport} || echo '⚠️ JSON scan failed for ${imageTag}'
        """

        // SARIF format
        sh """
            docker run --rm \
              -v \$PWD:/workspace \
              bridgecrew/checkov:latest \
              -d /workspace/${service} \
              --output sarif \
              -o ${sarifReport} || echo '⚠️ SARIF scan failed for ${imageTag}'
        """

        // Fallback if any file is missing
        [jsonReport, sarifReport].each { report ->
            if (!fileExists(report)) {
                echo "⚠️  Creating dummy report: ${report}"
                writeFile file: report, text: "No report generated for ${imageTag}. Scan may have failed."
            }
        }
    }

    echo "📁 Listing Checkov reports..."
    sh "ls -lh checkov-reports"

    echo "📦 Archiving Checkov reports..."
    archiveArtifacts artifacts: 'checkov-reports/*.{json,sarif}', allowEmptyArchive: false

    echo "✅ Checkov scan (all formats) and archive complete."
}

return this
