def scanAndArchiveFS() {
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
        def sourceDir = "src/${service}"
        def tableReport = "trivy-reports/${service}.txt"
        def jsonReport  = "trivy-reports/${service}.json"
        def sarifReport = "trivy-reports/${service}.sarif"

        echo "🔍 Scanning source code for: ${sourceDir}"

        // Table format
        sh """
            docker run --rm \
              -v "\$PWD/${sourceDir}:/app" \
              -v \$PWD:/root/.cache/ \
              aquasec/trivy:latest fs /app \
              --no-progress \
              --severity CRITICAL,HIGH \
              --format table \
              -o ${tableReport} || echo '⚠️  Table scan failed for ${service}'
        """

        // JSON format
        sh """
            docker run --rm \
              -v "\$PWD/${sourceDir}:/app" \
              -v \$PWD:/root/.cache/ \
              aquasec/trivy:latest fs /app \
              --no-progress \
              --severity CRITICAL,HIGH \
              --format json \
              -o ${jsonReport} || echo '⚠️  JSON scan failed for ${service}'
        """

        // SARIF format
        sh """
            docker run --rm \
              -v "\$PWD/${sourceDir}:/app" \
              -v \$PWD:/root/.cache/ \
              aquasec/trivy:latest fs /app \
              --no-progress \
              --severity CRITICAL,HIGH \
              --format sarif \
              -o ${sarifReport} || echo '⚠️  SARIF scan failed for ${service}'
        """

        // Fallback for missing reports
        [tableReport, jsonReport, sarifReport].each { report ->
            if (!fileExists(report)) {
                echo "⚠️  Creating dummy report: ${report}"
                writeFile file: report, text: "No report generated for ${service}. Scan may have failed."
            }
        }
    }

    echo "📁 Listing Trivy reports..."
    sh "ls -lh trivy-reports"

    echo "📦 Archiving Trivy source code scan reports..."
    archiveArtifacts artifacts: 'trivy-reports/*.{txt,json,sarif}', allowEmptyArchive: false

    echo "✅ Trivy source scan and archiving complete."
}

return this
