// groovy/PyflakesScan.groovy

def runPyflakesScan = {
    try {
        echo "[INFO] Starting Pyflakes scan..."

        // Running Pyflakes scan inside a Docker container
        docker.image('python:3.9').inside {
            // Install Pyflakes
            sh 'pip install pyflakes || true'

            // Run Pyflakes and output the result to a file
            sh 'pyflakes . > pyflakes-report.txt || true'
        }

        // Archiving the Pyflakes report to Jenkins
        archiveArtifacts allowEmptyArchive: true, artifacts: 'pyflakes-report.txt', followSymlinks: false

        // Post-scan actions
        echo "[INFO] Pyflakes scan completed successfully and report archived."

    } catch (Exception e) {
        echo "[ERROR] Pyflakes scan failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if Pyflakes scan is critical
    }
}

return [runPyflakesScan: runPyflakesScan]