def runZAPScan = {
    echo "[INFO] Starting OWASP ZAP scan..."

    // Step 1: Wait and fetch LoadBalancer IP or DNS
    def maxRetries = 10
    def retryInterval = 10
    def loadBalancerIP = ""

    for (int i = 0; i < maxRetries; i++) {
        loadBalancerIP = sh(script: "kubectl get svc my-app-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'", returnStdout: true).trim()
        if (!loadBalancerIP) {
            loadBalancerIP = sh(script: "kubectl get svc my-app-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'", returnStdout: true).trim()
        }
        if (loadBalancerIP) {
            break
        }
        echo "[INFO] Waiting for LoadBalancer IP/DNS... (${i + 1}/${maxRetries})"
        sleep(retryInterval)
    }

    if (!loadBalancerIP) {
        error "[ERROR] LoadBalancer IP/DNS not available after ${maxRetries * retryInterval} seconds"
    }

    env.LOAD_BALANCER_URL = "http://${loadBalancerIP}"
    echo "[INFO] LoadBalancer URL resolved to: ${env.LOAD_BALANCER_URL}"

    // Step 2: Run ZAP scan
    def reportDir = "${env.WORKSPACE}/zap_reports"
    def zapImage = "owasp/zap2docker-stable"

    sh "mkdir -p ${reportDir}"

    echo "[INFO] Running OWASP ZAP scan..."
    sh """
        docker run --rm -v ${reportDir}:/zap/wrk -t ${zapImage} \
        zap-full-scan.py -t ${env.LOAD_BALANCER_URL} -r zap_report.html
    """

    // Step 3: Archive the ZAP report
    archiveArtifacts allowEmptyArchive: false, artifacts: "zap_reports/zap_report.html"
    echo "[INFO] ZAP scan completed. Report archived."
}

return [runZAPScan: runZAPScan]
