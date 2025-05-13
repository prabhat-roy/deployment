def runGitleaksScanAndArchiveReports() {
    echo "📥 Pulling latest Gitleaks Docker image..."
    sh 'docker pull zricethezav/gitleaks:latest'

    def reportDir = "gitleaks-reports"
    def jsonReport = "${reportDir}/gitleaks-report.json"
    def sarifReport = "${reportDir}/gitleaks-report.sarif"

    echo "📂 Creating report directory..."
    sh "mkdir -p ${reportDir}"

    echo "🔍 Running Gitleaks scan on current directory..."
    sh """
        docker run --rm \
        -v \$PWD:/path \
        -w /path \
        zricethezav/gitleaks:latest detect \
        --source=. \
        --report-format=json \
        --report-path=${jsonReport} \
        || echo '⚠️ Gitleaks JSON scan completed with issues.'
    """

    // Optional SARIF format (for GitHub integration, etc.)
    sh """
        docker run --rm \
        -v \$PWD:/path \
        -w /path \
        zricethezav/gitleaks:latest detect \
        --source=. \
        --report-format=sarif \
        --report-path=${sarifReport} \
        || echo '⚠️ Gitleaks SARIF scan completed with issues.'
    """

    echo "📦 Archiving Gitleaks reports..."
    archiveArtifacts artifacts: "${reportDir}/*.json,${reportDir}/*.sarif", allowEmptyArchive: true

    echo "✅ Gitleaks scan completed and reports archived."
}

return this
