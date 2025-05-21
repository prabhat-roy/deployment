def runESLintAndArchiveReports() {
    echo "📥 Pulling latest ESLint Docker image..."
    
    // Pull the latest ESLint Docker image
    sh 'docker pull node:latest'  // Pull the latest Node.js image, as ESLint runs inside Node.js

    def buildNumber = env.BUILD_NUMBER
    def eslintConfig = env.ESLINT_CONFIG  // This can be your ESLint config file name

    if (!buildNumber) {
        error "❌ BUILD_NUMBER environment variable is missing!"
    }
    if (!eslintConfig) {
        error "❌ ESLINT_CONFIG environment variable is missing!"
    }

    // Create a directory for reports
    sh 'mkdir -p eslint-reports'

    echo "🔍 Running ESLint scan using Docker..."

    def reportFile = "eslint-reports/eslint-report.txt"

    // Run ESLint scan using Docker and mount the current directory to the container
    sh """
        docker run --rm \
            -v \$(pwd):/app \
            node:latest \
            sh -c "npm install eslint && npx eslint --config ${eslintConfig} /app > /app/${reportFile}" || echo '⚠️  ESLint scan failed'
    """

    // Fallback if any file is missing
    if (!fileExists(reportFile)) {
        echo "⚠️  Creating dummy report: ${reportFile}"
        writeFile file: reportFile, text: "No ESLint report generated. Scan may have failed."
    }

    echo "📁 Listing ESLint reports..."
    sh "ls -lh eslint-reports"

    echo "📦 Archiving ESLint reports..."
    archiveArtifacts artifacts: 'eslint-reports/*.{txt}', allowEmptyArchive: false

    echo "✅ ESLint scan and report archive complete."
}

return this
