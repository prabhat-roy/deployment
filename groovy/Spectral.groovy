def runSpectralScan = {
    echo "[INFO] Pulling the latest Spectral Docker image..."

    // Pull the latest Spectral Docker image
    sh 'docker pull spectralops/spectral-cli:latest'

    def services = [
        "adservice", "cartservice", "checkoutservice", "currencyservice",
        "emailservice", "frontend", "paymentservice", "productcatalogservice",
        "recommendationservice", "shippingservice"
    ]

    services.each { service ->
        def sourceDir = "src/${service}"
        def report = "workspace/logs/spectral-${service}.json"

        echo "[INFO] Scanning ${sourceDir} with Spectral..."

        // Run the scan for each service using Spectral
        sh """
            docker run --rm \
                -v "\${PWD}/${sourceDir}:/src" \
                spectralops/spectral-cli:latest lint /src --format json > ${report} || true
        """
    }

    echo "[INFO] Archiving Spectral scan reports..."

    // Archive all generated reports
    archiveArtifacts artifacts: 'workspace/logs/spectral-*.json', fingerprint: true

    echo "[SUCCESS] Spectral scan completed and reports archived successfully."
}

return [runSpectralScan: runSpectralScan]
