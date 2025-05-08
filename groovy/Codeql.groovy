// groovy/CodeqlScan.groovy

def runCodeqlScan = {
    try {
        echo "[INFO] Starting CodeQL scan..."

        // Ensure CodeQL CLI is installed (or use Docker)
        docker.image('github/codeql-action:latest').inside {
            // Setup the CodeQL environment (install CodeQL CLI)
            sh 'wget https://github.com/github/codeql-cli-binaries/releases/download/v2.0.2/codeql-linux64.tar.gz'
            sh 'tar -xvzf codeql-linux64.tar.gz'
            sh 'export PATH=$PATH:$(pwd)/codeql-linux64/codeql'

            // Initialize the CodeQL database
            sh 'codeql database create codeql-db --language=python --source-root=.'

            // Run CodeQL queries
            sh 'codeql database analyze codeql-db --format=sarif-latest --output=codeql-report.sarif'

            // Archive the SARIF report
            archiveArtifacts allowEmptyArchive: true, artifacts: 'codeql-report.sarif', followSymlinks: false
        }

        echo "[INFO] CodeQL scan completed and report archived."

    } catch (Exception e) {
        echo "[ERROR] CodeQL scan failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if CodeQL scan is critical
    }
}

return [runCodeqlScan: runCodeqlScan]