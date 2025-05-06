def call() {
    echo "📝 Verifying Codacy report..."
    def report = "${env.CODACY_REPORT}"
    if (fileExists(report)) {
        echo "✅ Report generated: ${report}"
    } else {
        error "❌ Codacy report not found!"
    }
}
