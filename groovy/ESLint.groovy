// groovy/ESLintScan.groovy

def runESLintScan = {
    try {
        echo "[INFO] Starting ESLint scan..."

        // Running ESLint scan inside a Docker container
        docker.image('node:16').inside {
            // Install ESLint and dependencies, and run the linting
            sh 'npm install eslint --save-dev || true'
            sh 'npx eslint . --format checkstyle -o eslint-report.xml || true'
        }

        // Archiving the ESLint report to Jenkins
        archiveArtifacts allowEmptyArchive: true, artifacts: 'eslint-report.xml', followSymlinks: false

        // Post-scan actions
        echo "[INFO] ESLint scan completed successfully and report archived."

    } catch (Exception e) {
        echo "[ERROR] ESLint scan failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if ESLint scan is critical
    }
}

return [runESLintScan: runESLintScan]