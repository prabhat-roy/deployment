def runCnodeScan = {
    try {
        echo "[INFO] Starting cnode scan for Kubernetes node security..."

        // Run cnode in Docker container to scan Kubernetes nodes
        sh '''
            docker run --rm \
                -v /var/run/docker.sock:/var/run/docker.sock \
                cnspec/cnode:latest --scan > /workspace/cnode-report.json
        '''

        // Archive the cnode scan report
        archiveArtifacts allowEmptyArchive: true, artifacts: '**/cnode-report.json', fingerprint: true
        echo "[INFO] cnode scan completed. Results archived."

    } catch (Exception e) {
        echo "[ERROR] cnode scan failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if critical
    }
}

return [runCnodeScan: runCnodeScan]