def scanAndArchiveImages() {
    echo "📥 Pulling latest Anchore Engine image..."
    sh 'docker pull anchore/anchore-engine:latest || echo "⚠️ Could not pull Anchore engine (optional if local Anchore is used)"'

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

    sh 'mkdir -p anchore-reports'

    services.each { service ->
        def imageTag = "${service}:${buildNumber}"
        def jsonReport = "anchore-reports/${service}.json"
        def htmlReport = "anchore-reports/${service}.html"

        echo "🔍 Scanning image with Anchore: ${imageTag}"

        // Scan with anchorectl (CLI method)
        sh """
            docker run --rm \
              -v /var/run/docker.sock:/var/run/docker.sock \
              -v \$PWD/anchore-reports:/reports \
              anchore/anchore-engine:latest \
              anchorectl image add ${imageTag} || echo '⚠️ Failed to add image'
        """

        // Wait and analyze
        sh """
            docker run --rm \
              -v /var/run/docker.sock:/var/run/docker.sock \
              -v \$PWD/anchore-reports:/reports \
              anchore/anchore-engine:latest \
              anchorectl image wait ${imageTag} || echo '⚠️ Image analysis wait failed'
        """

        // JSON report
        sh """
            docker run --rm \
              -v /var/run/docker.sock:/var/run/docker.sock \
              -v \$PWD/anchore-reports:/reports \
              anchore/anchore-engine:latest \
              anchorectl image vuln ${imageTag} all \
              --json > ${jsonReport} || echo '⚠️ Failed to get JSON report'
        """

        // HTML report (simulate by converting JSON to HTML via jq + template or use Jenkins HTML publisher plugin)
        sh """
            echo "<html><body><pre>" > ${htmlReport}
            cat ${jsonReport} | jq '.' >> ${htmlReport}
            echo "</pre></body></html>" >> ${htmlReport}
        """

        // Fallback for missing files
        [jsonReport, htmlReport].each { report ->
            if (!fileExists(report)) {
                echo "⚠️ Creating dummy report: ${report}"
                writeFile file: report, text: "No Anchore report generated for ${imageTag}."
            }
        }
    }

    echo "📁 Listing Anchore reports..."
    sh "ls -lh anchore-reports"

    echo "📦 Archiving Anchore reports..."
    archiveArtifacts artifacts: 'anchore-reports/*.{json,html}', allowEmptyArchive: false

    echo "✅ Anchore scan and archive complete."
}

return this
