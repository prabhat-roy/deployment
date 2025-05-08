// groovy/BrakemanScan.groovy

def runBrakemanScan = {
    try {
        echo "[INFO] Starting Brakeman scan..."

        // Ensure Brakeman is installed (can use Docker image or install directly)
        docker.image('dakota/brakeman:latest').inside {
            // Run Brakeman scan inside the Docker container
            sh 'bundle install'  // Install any necessary Ruby dependencies
            sh 'brakeman --no-progress --output brakeman-report.html'  // Run Brakeman scan and generate report

            // Archive the Brakeman report
            archiveArtifacts allowEmptyArchive: true, artifacts: 'brakeman-report.html', followSymlinks: false
        }

        echo "[INFO] Brakeman scan completed and report archived."

    } catch (Exception e) {
        echo "[ERROR] Brakeman scan failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if Brakeman scan is critical
    }
}

return [runBrakemanScan: runBrakemanScan]