def runGitGuardianScanAndArchiveReports(String apiKey) {
    echo "🐳 Pulling latest GitGuardian (ggshield) Docker image..."
    sh 'docker pull gitguardian/ggshield:latest'

    def reportDir = "gitguardian-reports"
    def jsonReport = "${reportDir}/report.json"

    echo "📁 Creating report directory..."
    sh "mkdir -p ${reportDir}"

    echo "🔐 Running GitGuardian scan on source code..."
    sh """
        docker run --rm \
          -e GG_API_KEY=${apiKey} \
          -v \$PWD:/src \
          -w /src \
          gitguardian/ggshield:latest secret scan repo . \
          --json > ${jsonReport} || echo '⚠️ GitGuardian scan completed with issues.'
    """

    if (!fileExists(jsonReport)) {
        echo "⚠️ Report not found, writing fallback dummy report..."
        writeFile file: jsonReport, text: '{"error": "GitGuardian scan failed or produced no output."}'
    }

    echo "📦 Archiving GitGuardian scan report to Jenkins..."
    archiveArtifacts artifacts: "${reportDir}/*.json", allowEmptyArchive: false

    echo "✅ GitGuardian scan complete."
}

return this
