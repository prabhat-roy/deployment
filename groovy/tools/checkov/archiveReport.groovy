def call() {
    echo "📦 Archiving Checkov report..."
    archiveArtifacts artifacts: "${env.REPORT_FILE}", allowEmptyArchive: false
}
