def call() {
    echo "🧹 Cleaning up Codacy scan artifacts..."
    sh "rm -f ${env.CODACY_REPORT}"
}
