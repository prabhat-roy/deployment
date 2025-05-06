def call() {
    echo "📝 Verifying Clair scan report..."
    def report = "${env.CLAIR_OUTPUT}"
    if (fileExists(report)) {
        echo "✅ Report generated: ${report}"
    } else {
        error "❌ Clair report not found!"
    }
}
