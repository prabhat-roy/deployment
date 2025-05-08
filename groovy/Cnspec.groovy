def runCnspecScan = {
    try {
        echo "[INFO] Starting cnspec scan for Kubernetes configuration security..."

        // Run cnspec in Docker container to scan Kubernetes configuration
        sh '''
            docker run --rm \
                -v /var/run/docker.sock:/var/run/docker.sock \
                -v ~/.kube:/root/.kube \
                cnspec/cnspec:latest --scan > /workspace/cnspec-report.json
        '''

        // Archive the cnspec scan report
        archiveArtifacts allowEmptyArchive: true, artifacts: '**/cnspec-report.json', fingerprint: true
        echo "[INFO] cnspec scan completed. Results archived."

    } catch (Exception e) {
        echo "[ERROR] cnspec scan failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if critical
    }
}

return [runCnspecScan: runCnspecScan]