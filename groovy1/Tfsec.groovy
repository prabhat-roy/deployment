def runTfsecScan = {
    try {
        echo "[INFO] Starting tfsec scan for Terraform code security..."

        // Docker command to run tfsec security scan
        sh '''
            docker run --rm \
                -v $(pwd):/workspace \
                quay.io/tfsec/tfsec:latest /workspace --format json --out /workspace/tfsec-report.json
        '''

        // Archive the tfsec scan results
        archiveArtifacts allowEmptyArchive: true, artifacts: '**/tfsec-report.json', fingerprint: true
        echo "[INFO] tfsec scan completed. Results archived."

    } catch (Exception e) {
        echo "[ERROR] tfsec scan failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if critical
    }
}

return [runTfsecScan: runTfsecScan]