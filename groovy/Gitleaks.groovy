// groovy/GitleaksScan.groovy

def runGitleaks = {
    try {
        echo "[INFO] Starting Gitleaks scan..."

        // Running Gitleaks inside a Docker container
        docker.image('zricethezav/gitleaks:v8.6.0').inside {
            // Run Gitleaks scan
            sh '''
                gitleaks detect --source=. --report=gitleaks-report.json || true
            '''
        }

        // Archiving the Gitleaks report to Jenkins
        archiveArtifacts allowEmptyArchive: true, artifacts: 'gitleaks-report.json', followSymlinks: false

        // Post-scan actions
        echo "[INFO] Gitleaks scan completed and report archived."

    } catch (Exception e) {
        echo "[ERROR] Gitleaks scan failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if Gitleaks scan is critical
    }
}

return [runGitleaks: runGitleaks]