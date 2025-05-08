def runKubeBenchScan = {
    try {
        echo "[INFO] Starting kube-bench scan for Kubernetes security benchmark..."

        // Run kube-bench in a Docker container
        sh '''
            docker run --rm \
                -v /var/run/docker.sock:/var/run/docker.sock \
                -v $(pwd):/workspace \
                aquasec/kube-bench:latest --version 1.21 --json > /workspace/kube-bench-report.json
        '''

        // Archive the kube-bench report
        archiveArtifacts allowEmptyArchive: true, artifacts: '**/kube-bench-report.json', fingerprint: true
        echo "[INFO] kube-bench scan completed. Results archived."

    } catch (Exception e) {
        echo "[ERROR] kube-bench scan failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if critical
    }
}

return [runKubeBenchScan: runKubeBenchScan]