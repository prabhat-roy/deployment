def runKicsScan = {
    try {
        echo "[INFO] Starting KICS scan for Infrastructure as Code security..."

        // Docker command to run KICS scan
        sh '''
            docker run --rm \
                -v $(pwd):/workspace \
                checkmarx/kics:latest scan --repo /workspace --output /workspace/kics-report.json
        '''

        // Archive the KICS scan results
        archiveArtifacts allowEmptyArchive: true, artifacts: '**/kics-report.json', fingerprint: true
        echo "[INFO] KICS scan completed. Results archived."

    } catch (Exception e) {
        echo "[ERROR] KICS scan failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if critical
    }
}

return [runKicsScan: runKicsScan]