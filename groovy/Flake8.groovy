// groovy/Flake8Scan.groovy

def runFlake8Scan = {
    try {
        echo "[INFO] Starting Flake8 scan..."

        // Running Flake8 scan inside a Docker container
        docker.image('python:3.9').inside {
            // Install flake8 inside the container and run the scan
            sh 'pip install flake8'
            sh 'flake8 --output-file=flake8-report.txt . || true'
        }

        // Archiving the Flake8 report to Jenkins
        archiveArtifacts allowEmptyArchive: true, artifacts: 'flake8-report.txt', followSymlinks: false

        // Post-scan actions
        echo "[INFO] Flake8 scan completed successfully and report archived."

    } catch (Exception e) {
        echo "[ERROR] Flake8 scan failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if Flake8 scan is critical
    }
}

return [runFlake8Scan: runFlake8Scan]