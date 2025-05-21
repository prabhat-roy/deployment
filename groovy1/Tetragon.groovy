def runTetragonScan = {
    try {
        echo "[INFO] Starting Tetragon security scan..."

        // Run Tetragon to monitor security and performance of Kubernetes workloads
        sh '''
            kubectl apply -k https://github.com/cilium/tetragon//examples/k8s/tetragon-agent
        '''

        // Get the status of the Tetragon agent to ensure it's running
        sh 'kubectl get pods -n tetragon'

        // Run a security scan or monitoring job with Tetragon (example for demonstration)
        sh '''
            kubectl logs -n tetragon -l app=tetragon -c tetragon-agent
        '''

        // Archive the logs or results (could be customized to include specific logs or outputs)
        archiveArtifacts allowEmptyArchive: true, artifacts: '**/tetragon-*.log', fingerprint: true
        echo "[INFO] Tetragon scan completed and results archived."

    } catch (Exception e) {
        echo "[ERROR] Tetragon security scan failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if critical
    }
}

return [runTetragonScan: runTetragonScan]