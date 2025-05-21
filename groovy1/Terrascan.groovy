def runTerrascanScan = {
    try {
        echo "[INFO] Starting Terrascan scan for Terraform code security..."

        // Docker command to run Terrascan security scan
        sh '''
            docker run --rm \
                -v $(pwd):/workspace \
                terrascan/terrascan:latest scan -d /workspace --format json -o /workspace/terrascan-report.json
        '''

        // Archive the Terrascan scan results
        archiveArtifacts allowEmptyArchive: true, artifacts: '**/terrascan-report.json', fingerprint: true
        echo "[INFO] Terrascan scan completed. Results archived."

    } catch (Exception e) {
        echo "[ERROR] Terrascan scan failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if critical
    }
}

return [runTerrascanScan: runTerrascanScan]