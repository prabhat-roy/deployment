// groovy/LicenseCheck.groovy

def runLicenseChecker = {
    try {
        echo "[INFO] Starting License Checker..."

        // Ensure license-checker is installed (you can install it using npm if it's not present)
        sh 'npm install -g license-checker'

        // Run the license checker to generate the license report
        sh 'license-checker --json > license-report.json'

        // Archive the License Checker report
        archiveArtifacts allowEmptyArchive: true, artifacts: '**/license-report.json', followSymlinks: false
        
        echo "[INFO] License Checker completed and report archived."

    } catch (Exception e) {
        echo "[ERROR] License Checker failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if License Checker is critical
    }
}

return [runLicenseChecker: runLicenseChecker]