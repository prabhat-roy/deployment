def runKicsCleanScan = {
    try {
        echo "[INFO] Starting KICS clean scan for code cleanliness..."

        // Docker command to run Keep It Clean Scanner
        sh '''
            docker run --rm \
                -v $(pwd):/workspace \
                keepitclean/kics-clean:latest scan --repo /workspace --output /workspace/kics-clean-report.json
        '''

        // Archive the KICS clean scan results
        archiveArtifacts allowEmptyArchive: true, artifacts: '**/kics-clean-report.json', fingerprint: true
        echo "[INFO] KICS clean scan completed. Results archived."

    } catch (Exception e) {
        echo "[ERROR] KICS clean scan failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if critical
    }
}

return [runKicsCleanScan: runKicsCleanScan]