def call() {
    echo "📦 Archiving Codacy report..."
    archiveArtifacts artifacts: "${env.CODACY_REPORT}", allowEmptyArchive: false
}
