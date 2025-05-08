// groovy/PylintScan.groovy

def runPylintScan = {
    try {
        echo "[INFO] Starting Pylint scan..."

        // Running Pylint scan inside a Docker container
        docker.image('pylint/pylint').inside {
            sh 'pylint --output-format=json --reports=y . > pylint-report.json || true'
        }

        // Archiving the Pylint report to Jenkins
        archiveArtifacts allowEmptyArchive: true, artifacts: 'pylint-report.json', followSymlinks: false

        // Post-scan actions
        echo "[INFO] Pylint scan completed successfully and report archived."

    } catch (Exception e) {
        echo "[ERROR] Pylint scan failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if Pylint scan is critical
    }
}

return [runPylintScan: runPylintScan]