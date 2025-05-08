def runKubeHunterScan = {
    try {
        echo "[INFO] Starting kube-hunter scan for Kubernetes cluster security..."

        // Run kube-hunter in a Docker container
        sh '''
            docker run --rm \
                -v /var/run/docker.sock:/var/run/docker.sock \
                --network host \
                aquasec/kube-hunter:latest --scan --json > /workspace/kube-hunter-report.json
        '''

        // Archive the kube-hunter report
        archiveArtifacts allowEmptyArchive: true, artifacts: '**/kube-hunter-report.json', fingerprint: true
        echo "[INFO] kube-hunter scan completed. Results archived."

    } catch (Exception e) {
        echo "[ERROR] kube-hunter scan failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if critical
    }
}

return [runKubeHunterScan: runKubeHunterScan]