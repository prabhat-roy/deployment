// groovy/BanditScan.groovy

def runBanditScan = {
    try {
        echo "[INFO] Starting Bandit security scan..."

        // Running Bandit scan inside a Docker container
        docker.image('pyupio/bandit').inside {
            sh 'bandit -r . -f json -o bandit-report.json || true'
        }

        // Archiving the Bandit report to Jenkins
        archiveArtifacts allowEmptyArchive: true, artifacts: 'bandit-report.json', followSymlinks: false

        // Post-scan actions
        echo "[INFO] Bandit scan completed successfully and report archived."

    } catch (Exception e) {
        echo "[ERROR] Bandit scan failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if Bandit scan is critical
    }
}

return [runBanditScan: runBanditScan]