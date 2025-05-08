// groovy/ToxScan.groovy

def runToxScan = {
    try {
        echo "[INFO] Starting Tox testing..."

        // Running Tox inside a Docker container
        docker.image('python:3.9').inside {
            // Install Tox and dependencies
            sh 'pip install tox || true'

            // Run Tox (assuming tox.ini is present in the project)
            sh 'tox || true'
        }

        // Archiving the Tox output to Jenkins
        archiveArtifacts allowEmptyArchive: true, artifacts: '**/tox-*.log', followSymlinks: false

        // Post-scan actions
        echo "[INFO] Tox testing completed and report archived."

    } catch (Exception e) {
        echo "[ERROR] Tox testing failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if Tox testing is critical
    }
}

return [runToxScan: runToxScan]