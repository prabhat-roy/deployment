def runGolangCILintAndArchiveReports() {
    echo "📥 Pulling latest golangci-lint Docker image..."
    sh 'docker pull golangci/golangci-lint:latest'

    def reportDir = 'golangci-lint-reports'
    def txtReport = "${reportDir}/report.txt"
    def jsonReport = "${reportDir}/report.json"
    def sarifReport = "${reportDir}/report.sarif"

    sh "mkdir -p ${reportDir}"

    echo "🔍 Running golangci-lint scan (text)..."
    sh """
        docker run --rm \
            -v \$PWD:/app \
            -w /app \
            golangci/golangci-lint:latest \
            golangci-lint run ./... \
            --out-format tab > ${txtReport} || echo '⚠️ Issues found during text scan.'
    """

    echo "🔍 Running golangci-lint scan (JSON)..."
    sh """
        docker run --rm \
            -v \$PWD:/app \
            -w /app \
            golangci/golangci-lint:latest \
            golangci-lint run ./... \
            --out-format json > ${jsonReport} || echo '⚠️ Issues found during JSON scan.'
    """

    echo "🔍 Running golangci-lint scan (SARIF)..."
    sh """
        docker run --rm \
            -v \$PWD:/app \
            -w /app \
            golangci/golangci-lint:latest \
            golangci-lint run ./... \
            --out-format sarif > ${sarifReport} || echo '⚠️ Issues found during SARIF scan.'
    """

    // Fallback for missing reports
    [txtReport, jsonReport, sarifReport].each { report ->
        if (!fileExists(report)) {
            echo "⚠️ Creating dummy report: ${report}"
            writeFile file: report, text: "No report generated. Linting may have failed."
        }
    }

    echo "📦 Archiving all golangci-lint reports..."
    archiveArtifacts artifacts: "${reportDir}/*.{txt,json,sarif}", allowEmptyArchive: false

    echo "✅ GolangCI-Lint scan (all formats) complete."
}

return this
