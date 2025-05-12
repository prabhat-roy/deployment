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

        def tableReport = "trivy-reports/${service}.txt"
        def jsonReport  = "trivy-reports/${service}.json"
        def sarifReport = "trivy-reports/${service}.sarif"

        echo "🔍 Scanning image in all formats: ${imageTag}"

        // Table format
        sh """
            docker run --rm \
              -v /var/run/docker.sock:/var/run/docker.sock \
              -v \$PWD:/root/.cache/ \
              aquasec/trivy:latest image \
              --no-progress \
              --severity CRITICAL,HIGH \
              --format table \
              -o ${tableReport} \
              ${imageTag} || echo '⚠️  Table scan failed for ${imageTag}'
        """

        // JSON format
        sh """
            docker run --rm \
              -v /var/run/docker.sock:/var/run/docker.sock \
              -v \$PWD:/root/.cache/ \
              aquasec/trivy:latest image \
              --no-progress \
              --severity CRITICAL,HIGH \
              --format json \
              -o ${jsonReport} \
              ${imageTag} || echo '⚠️  JSON scan failed for ${imageTag}'
        """

        // SARIF format
        sh """
            docker run --rm \
              -v /var/run/docker.sock:/var/run/docker.sock \
              -v \$PWD:/root/.cache/ \
              aquasec/trivy:latest image \
              --no-progress \
              --severity CRITICAL,HIGH \
              --format sarif \
              -o ${sarifReport} \
              ${imageTag} || echo '⚠️  SARIF scan failed for ${imageTag}'
        """

        // Fallback if any file is missing
        [tableReport, jsonReport, sarifReport].each { report ->
            if (!fileExists(report)) {
                echo "⚠️  Creating dummy report: ${report}"
                writeFile file: report, text: "No report generated for ${imageTag}. Scan may have failed."
            }
        }
    }

    echo "📁 Listing Trivy reports..."
    sh "ls -lh trivy-reports"

    echo "📦 Archiving Trivy reports..."
    archiveArtifacts artifacts: 'trivy-reports/*.{txt,json,sarif}', allowEmptyArchive: false

    echo "✅ Trivy scan (all formats) and archive complete."
}

return this
