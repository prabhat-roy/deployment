def runKubeauditScan = {
    try {
        echo "[INFO] Starting Kubeaudit scan for Kubernetes security..."

        // Run kubeaudit in Docker container to audit the Kubernetes cluster security
        sh '''
            docker run --rm \
                -v ~/.kube:/root/.kube \
                quay.io/guillaumelaurent/kubeaudit:latest audit > /workspace/kubeaudit-report.json
        '''

        // Archive the kubeaudit scan report
        archiveArtifacts allowEmptyArchive: true, artifacts: '**/kubeaudit-report.json', fingerprint: true
        echo "[INFO] Kubeaudit scan completed. Results archived."

    } catch (Exception e) {
        echo "[ERROR] Kubeaudit scan failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if critical
    }
}

return [runKubeauditScan: runKubeauditScan]