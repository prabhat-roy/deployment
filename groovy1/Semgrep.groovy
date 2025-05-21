def scanWithSemgrep = {
    def services = [
        "adservice", "cartservice", "checkoutservice", "currencyservice",
        "emailservice", "frontend", "paymentservice", "productcatalogservice",
        "recommendationservice", "shippingservice"
    ]

    echo "[INFO] Pulling the latest Semgrep Docker image..."
    // Pull the latest Semgrep Docker image
    sh 'docker pull returntocorp/semgrep'

    services.each { service ->
        def sourceDir = "src/${service}"
        def report = "workspace/logs/semgrep-${service}.json"

        echo "[INFO] Scanning ${sourceDir} with Semgrep..."

        // Run the scan for each service
        sh """
            docker run --rm \
                -v "\${PWD}/${sourceDir}:/src" \
                returntocorp/semgrep \
                semgrep --config=auto --json > ${report} || true
        """
    }

    // Archive all generated reports
    echo "[INFO] Archiving Semgrep scan reports..."
    archiveArtifacts artifacts: 'workspace/logs/semgrep-*.json', fingerprint: true

    echo "[SUCCESS] Semgrep scan completed and reports archived successfully."
}

return [scanWithSemgrep: scanWithSemgrep]
