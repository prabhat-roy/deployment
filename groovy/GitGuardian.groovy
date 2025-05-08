// groovy/GitGuardianScan.groovy

def runGitGuardianScan = {
    try {
        echo "[INFO] Starting GitGuardian scan..."

        // Ensure GitGuardian CLI is installed (or use Docker)
        docker.image('gitguardian/gitguardian:latest').inside {
            // Run GitGuardian scan on the Git repository
            sh '''
                gitguardian scan --json --report trufflehog-report.json .
            '''
        }

        // Archiving the GitGuardian report to Jenkins
        archiveArtifacts allowEmptyArchive: true, artifacts: 'gitguardian-report.json', followSymlinks: false

        // Post-scan actions
        echo "[INFO] GitGuardian scan completed and report archived."

    } catch (Exception e) {
        echo "[ERROR] GitGuardian scan failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if GitGuardian scan is critical
    }
}

return [runGitGuardianScan: runGitGuardianScan]