def scanDockerImages = {
    try {
        echo "[INFO] Starting Docker image scan process with Docker Scout..."

        // List of microservices to scan
        def services = [
            'frontend',
            'recommendationservice',
            'paymentservice',
            'checkoutservice',
            'shippingservice',
            'cartservice',
            'currencyservice',
            'emailservice'
        ]

        // Docker Scout image
        def dockerScoutImage = "docker/scout:latest"

        // Report directory
        def reportDir = 'workspace/reports/docker-scout'
        sh "mkdir -p ${reportDir}"

        // Pull the latest Docker Scout image once
        echo "[INFO] Pulling Docker Scout image..."
        sh "docker pull ${dockerScoutImage}"

        services.each { service ->
            def imageTag = "${service}:${env.BUILD_NUMBER}"
            def reportFile = "${reportDir}/${service}_scan_report_${env.BUILD_NUMBER}.txt"

            echo "[INFO] Scanning Docker image ${imageTag} with Docker Scout..."

            sh """
                docker run --rm \
                    -v /var/run/docker.sock:/var/run/docker.sock \
                    ${dockerScoutImage} \
                    cves ${imageTag} > ${reportFile} || echo '[WARN] Scan failed for ${imageTag}'
            """

            echo "[INFO] Report for ${service} saved at ${reportFile}"
        }

        echo "[INFO] Archiving Docker Scout scan reports..."
        archiveArtifacts artifacts: "${reportDir}/*.txt", allowEmptyArchive: true

        echo "[✔] All Docker Scout reports archived."
    } catch (Exception e) {
        echo "[ERROR] Docker Scout scan failed: ${e.message}"
        throw e
    }
}

return [scanDockerImages: scanDockerImages]
