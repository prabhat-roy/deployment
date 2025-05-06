def call() {
    echo "📦 Archiving Clair report..."
    archiveArtifacts artifacts: "${env.CLAIR_OUTPUT}", allowEmptyArchive: false
}
