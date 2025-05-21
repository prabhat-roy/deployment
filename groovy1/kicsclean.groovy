def pullAndScanIaC() {
    echo "📥 Pulling the latest KICS Docker image..."
    sh 'docker pull checkmarx/kics:latest'  // Pull the latest KICS Docker image

    def iacPath = env.IAC_PATH
    def buildNumber = env.BUILD_NUMBER

    if (!iacPath) {
        error "❌ IAC_PATH environment variable is missing! Please set the path to your IaC code."
    }
    if (!buildNumber) {
        error "❌ BUILD_NUMBER environment variable is missing!"
    }

    echo "🔍 Scanning Infrastructure as Code in path: ${iacPath}"

    // Create a directory for the reports
    sh 'mkdir -p kics-reports'

    // Run the KICS scan
    sh """
        docker run --rm \
          -v ${iacPath}:${iacPath} \
          -v \$PWD/kics-reports:/kics-reports \
          checkmarx/kics:latest scan \
          --path ${iacPath} \
          --output /kics-reports/kics-report-${buildNumber}.json
    """

    // Check if report was generated
    def reportFile = "kics-reports/kics-report-${buildNumber}.json"
    if (!fileExists(reportFile)) {
        error "❌ KICS scan report was not generated."
    }

    echo "📁 Listing KICS scan reports..."
    sh "ls -lh kics-reports"

    echo "📦 Archiving KICS reports..."
    archiveArtifacts artifacts: 'kics-reports/*.json', allowEmptyArchive: false

    echo "✅ KICS scan and report archiving complete."
}

return this
