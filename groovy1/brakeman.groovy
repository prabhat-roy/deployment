def scanAndArchiveReports() {
    echo "📥 Pulling latest Brakeman Docker image..."
    sh 'docker pull brakeman/brakeman:latest'

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

    sh 'mkdir -p brakeman-reports'

    services.each { service ->
        def imageTag = "${service}:${buildNumber}"

        def htmlReport = "brakeman-reports/${service}_brakeman.html"
        def jsonReport = "brakeman-reports/${service}_brakeman.json"
        def txtReport  = "brakeman-reports/${service}_brakeman.txt"

        echo "🔍 Scanning image for security vulnerabilities: ${imageTag}"

        // HTML format
        sh """
            docker run --rm \
              -v \$PWD:/mnt/project \
              brakeman/brakeman:latest \
              -f html \
              -o ${htmlReport} \
              /mnt/project || echo '⚠️  HTML scan failed for ${imageTag}'
        """

        // JSON format
        sh """
            docker run --rm \
              -v \$PWD:/mnt/project \
              brakeman/brakeman:latest \
              -f json \
              -o ${jsonReport} \
              /mnt/project || echo '⚠️  JSON scan failed for ${imageTag}'
        """

        // Text format
        sh """
            docker run --rm \
              -v \$PWD:/mnt/project \
              brakeman/brakeman:latest \
              -f txt \
              -o ${txtReport} \
              /mnt/project || echo '⚠️  Text scan failed for ${imageTag}'
        """

        // Fallback if any file is missing
        [htmlReport, jsonReport, txtReport].each { report ->
            if (!fileExists(report)) {
                echo "⚠️  Creating dummy report: ${report}"
                writeFile file: report, text: "No report generated for ${imageTag}. Scan may have failed."
            }
        }
    }

    echo "📁 Listing Brakeman reports..."
    sh "ls -lh brakeman-reports"

    echo "📦 Archiving Brakeman reports..."
    archiveArtifacts artifacts: 'brakeman-reports/*.{html,json,txt}', allowEmptyArchive: false

    echo "✅ Brakeman scan (all formats) and archive complete."
}

return this
