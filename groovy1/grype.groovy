def scanAndArchiveImages() {
    echo "📥 Pulling latest Grype image..."
    sh 'docker pull anchore/grype:latest'

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

    sh 'mkdir -p grype-reports'

    services.each { service ->
        def imageTag = "${service}:${buildNumber}"

        def tableReport = "grype-reports/${service}.txt"
        def jsonReport  = "grype-reports/${service}.json"
        def sarifReport = "grype-reports/${service}.cyclonedx.json"

        echo "🔍 Scanning image in all formats: ${imageTag}"

        // Table format
        sh """
            docker run --rm \
              -v /var/run/docker.sock:/var/run/docker.sock \
              -v \$PWD:/scan \
              anchore/grype:latest \
              ${imageTag} \
              -o table > ${tableReport} || echo '⚠️  Table scan failed for ${imageTag}'
        """

        // JSON format
        sh """
            docker run --rm \
              -v /var/run/docker.sock:/var/run/docker.sock \
              -v \$PWD:/scan \
              anchore/grype:latest \
              ${imageTag} \
              -o json > ${jsonReport} || echo '⚠️  JSON scan failed for ${imageTag}'
        """

        // CycloneDX (acts like SARIF for tooling)
        sh """
            docker run --rm \
              -v /var/run/docker.sock:/var/run/docker.sock \
              -v \$PWD:/scan \
              anchore/grype:latest \
              ${imageTag} \
              -o cyclonedx-json > ${sarifReport} || echo '⚠️  CycloneDX scan failed for ${imageTag}'
        """

        // Fallback if any file is missing
        [tableReport, jsonReport, sarifReport].each { report ->
            if (!fileExists(report)) {
                echo "⚠️  Creating dummy report: ${report}"
                writeFile file: report, text: "No report generated for ${imageTag}. Scan may have failed."
            }
        }
    }

    echo "📁 Listing Grype reports..."
    sh "ls -lh grype-reports"

    echo "📦 Archiving Grype reports..."
    archiveArtifacts artifacts: 'grype-reports/*.{txt,json,cyclonedx.json}', allowEmptyArchive: false

    echo "✅ Grype scan (all formats) and archive complete."
}

return this
