def call() {
    echo "📝 Generating Checkov report..."
    def reportPath = "${env.REPORT_FILE ?: 'checkov_report.json'}"
    if (fileExists(reportPath)) {
        echo "✅ Report generated: ${reportPath}"
    } else {
        error "❌ Checkov report not found!"
    }
}
