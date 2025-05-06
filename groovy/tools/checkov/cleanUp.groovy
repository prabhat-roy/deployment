def call() {
    echo "🧹 Cleaning up Checkov report file..."
    sh "rm -f ${env.REPORT_FILE}"
}
