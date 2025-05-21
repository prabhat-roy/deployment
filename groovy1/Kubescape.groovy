def runKubescapeScan = {
    try {
        echo "[INFO] Starting Kubescape scan for Kubernetes resources..."

        // Docker command to run Kubescape security scan
        sh '''
            docker run --rm \
                -v $(pwd):/workspace \
                -v /var/run/docker.sock:/var/run/docker.sock \
                armosec/kubescape scan --exclude-namespaces kube-system --format json --output /workspace/kubescape-report.json
        '''

        // Archive the kubescape scan results
        archiveArtifacts allowEmptyArchive: true, artifacts: '**/kubescape-report.json', fingerprint: true
        echo "[INFO] Kubescape scan completed. Results archived."

    } catch (Exception e) {
        echo "[ERROR] Kubescape scan failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if critical
    }
}

return [runKubescapeScan: runKubescapeScan]