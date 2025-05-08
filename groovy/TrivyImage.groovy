def scanDockerImagesWithTrivyDocker = {
    echo "[INFO] Starting Trivy Docker image scan..."

    // Define microservices
    def services = ['frontend', 'recommendationservice', 'paymentservice', 'checkoutservice', 'shippingservice', 'cartservice', 'currencyservice', 'emailservice']

    // Define Trivy image
    def trivyImage = "aquasec/trivy:latest"

    // Define report directory
    def reportDir = 'workspace/reports/trivy-docker'
    sh "mkdir -p ${reportDir}"

    // Pull Trivy image once
    echo "[INFO] Pulling Trivy Docker image..."
    sh "docker pull ${trivyImage}"

    // Run Trivy scan on each service
    services.each { service ->
        def imageTag = "${service}:${env.BUILD_NUMBER}"
        def reportFile = "${reportDir}/${service}_trivy_report_${env.BUILD_NUMBER}.txt"

        echo "[INFO] Scanning Docker image ${imageTag} with Trivy..."
        sh """
            docker run --rm \
              -v /var/run/docker.sock:/var/run/docker.sock \
              ${trivyImage} image --scanners vuln ${imageTag} > ${reportFile} || echo '[WARN] Trivy scan failed for ${imageTag}'
        """

        echo "[INFO] Report saved for ${service}: ${reportFile}"
    }

    // Archive all reports
    echo "[INFO] Archiving Trivy scan reports..."
    archiveArtifacts artifacts: "${reportDir}/*.txt", allowEmptyArchive: true

    echo "[✔] Trivy Docker image scans completed and archived."
}

return [scanDockerImagesWithTrivyDocker: scanDockerImagesWithTrivyDocker]
