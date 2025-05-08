// groovy/TernCheck.groovy

def runTernCheck = {
    try {
        echo "[INFO] Starting Tern License Checker..."

        // Ensure Tern is installed in the project directory
        sh 'npm install -g tern'

        // Run Tern to generate the license audit report
        sh 'tern --audit > tern-report.json'

        // Archive the Tern audit report for later review
        archiveArtifacts allowEmptyArchive: true, artifacts: '**/tern-report.json', followSymlinks: false
        
        echo "[INFO] Tern License Checker completed and report archived."

    } catch (Exception e) {
        echo "[ERROR] Tern License Checker failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if Tern check is critical
    }
}

return [runTernCheck: runTernCheck]