// groovy/FossaScan.groovy

def runFossaScan = {
    try {
        echo "[INFO] Starting FOSSA scan..."

        // Ensure FOSSA CLI is installed (or use Docker)
        docker.image('fossa/cli:latest').inside {
            // Run FOSSA scan for the repository
            sh '''
                # FOSSA authentication (replace with your actual API key)
                fossa init --token YOUR_FOSSA_API_TOKEN
                
                # Run the scan
                fossa analyze --format json > fossa-report.json
            '''
        }

        // Archiving the FOSSA report to Jenkins
        archiveArtifacts allowEmptyArchive: true, artifacts: 'fossa-report.json', followSymlinks: false

        // Post-scan actions
        echo "[INFO] FOSSA scan completed and report archived."

    } catch (Exception e) {
        echo "[ERROR] FOSSA scan failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if FOSSA scan is critical
    }
}

return [runFossaScan: runFossaScan]