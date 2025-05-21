// groovy/TruffleHogScan.groovy

def runTruffleHog = {
    try {
        echo "[INFO] Starting TruffleHog scan..."

        // Running TruffleHog inside a Docker container
        docker.image('trufflesecurity/trufflehog:latest').inside {
            // Run TruffleHog scan on the Git repository
            sh '''
                trufflehog --json --no-progress --max_depth=50 --report-file=trufflehog-report.json --directory=. || true
            '''
        }

        // Archiving the TruffleHog report to Jenkins
        archiveArtifacts allowEmptyArchive: true, artifacts: 'trufflehog-report.json', followSymlinks: false

        // Post-scan actions
        echo "[INFO] TruffleHog scan completed and report archived."

    } catch (Exception e) {
        echo "[ERROR] TruffleHog scan failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if TruffleHog scan is critical
    }
}

return [runTruffleHog: runTruffleHog]