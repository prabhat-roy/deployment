def scanAndArchiveReports() {
    echo "🔄 Running CodeQL scan..."
    
    // Define the GitHub repository
    def repoName = env.GIT_REPO_NAME
    def buildNumber = env.BUILD_NUMBER
    def outputDir = "codeql-reports"
    
    if (!repoName) {
        error "❌ GIT_REPO_NAME environment variable is missing!"
    }
    if (!buildNumber) {
        error "❌ BUILD_NUMBER environment variable is missing!"
    }

    // Pull the latest CodeQL Docker image
    echo "📥 Pulling latest CodeQL image..."
    sh 'docker pull github/codeql-cli:latest'

    // Create directory for reports
    sh "mkdir -p ${outputDir}"

    // Run CodeQL scan for the specific repository and language (e.g., JavaScript)
    echo "🔍 Running CodeQL analysis for the repository ${repoName}..."

    sh """
        docker run --rm \
            -v \$PWD:/src \
            github/codeql-cli:latest \
            codeql database create ${outputDir}/codeql-database --language=javascript --source-root=/src
    """

    // Run the query to find vulnerabilities
    echo "🛠 Running CodeQL queries..."
    sh """
        docker run --rm \
            -v \$PWD:/src \
            github/codeql-cli:latest \
            codeql database analyze ${outputDir}/codeql-database --format=sarif-latest --output=${outputDir}/codeql-scan.sarif
    """

    // Check if the report was generated
    if (!fileExists("${outputDir}/codeql-scan.sarif")) {
        error "❌ CodeQL scan failed. SARIF report not found!"
    }

    // Archive the CodeQL SARIF report
    echo "📦 Archiving CodeQL reports..."
    archiveArtifacts artifacts: "${outputDir}/*.sarif", allowEmptyArchive: false

    echo "✅ CodeQL scan completed and reports archived."
}

return this
