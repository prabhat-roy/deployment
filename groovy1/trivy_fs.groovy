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

    def workspace = pwd()
    def reportsDir = "${workspace}/trivy-reports"
    sh "mkdir -p '${reportsDir}'"

    services.each { service ->
        def sourceDir = "${workspace}/src/${service}"
        def tableReport = "${reportsDir}/${service}.txt"
        def jsonReport  = "${reportsDir}/${service}.json"
        def sarifReport = "${reportsDir}/${service}.sarif"

        echo "🔍 Scanning source code for: ${sourceDir}"

        // Table format
        sh """
            docker run --rm \
              -v '${sourceDir}:/app' \
              -v '${reportsDir}:/reports' \
              -v '${workspace}:/root/.cache/' \
              aquasec/trivy:latest fs /app \
              --no-progress \
              --severity CRITICAL,HIGH \
              --format table \
              -o /reports/${service}.txt || echo '⚠️  Table scan failed for ${service}'
        """

        // JSON format
        sh """
            docker run --rm \
              -v '${sourceDir}:/app' \
              -v '${reportsDir}:/reports' \
              -v '${workspace}:/root/.cache/' \
              aquasec/trivy:latest fs /app \
              --no-progress \
              --severity CRITICAL,HIGH \
              --format json \
              -o /reports/${service}.json || echo '⚠️  JSON scan failed for ${service}'
        """

        // SARIF format
        sh """
            docker run --rm \
              -v '${sourceDir}:/app' \
              -v '${reportsDir}:/reports' \
              -v '${workspace}:/root/.cache/' \
              aquasec/trivy:latest fs /app \
              --no-progress \
              --severity CRITICAL,HIGH \
              --format sarif \
              -o /reports/${service}.sarif || echo '⚠️  SARIF scan failed for ${service}'
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
    sh "ls -lh '${reportsDir}'"

    echo "📦 Archiving Trivy source code scan reports..."
    archiveArtifacts artifacts: 'trivy-reports/*.txt,trivy-reports/*.json,trivy-reports/*.sarif', allowEmptyArchive: false

    echo "🧹 Cleaning up Trivy containers and images..."
    sh '''
        # Remove any exited Trivy containers (though --rm means none should exist)
        docker ps -a --filter "ancestor=aquasec/trivy:latest" --filter "status=exited" -q | xargs -r docker rm

        # Remove the Trivy image itself (optional, uncomment if needed)
        docker rmi aquasec/trivy:latest || true

        # Remove any dangling images
        docker image prune -f || true
    '''


    echo "✅ Trivy source scan and cleanup complete."
}

return this
