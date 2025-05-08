def scanImagesWithSnyk = {
    echo "[INFO] Starting Docker image scan process with Snyk..."

    // Define microservices
    def services = ['frontend', 'recommendationservice', 'paymentservice', 'checkoutservice', 'shippingservice', 'cartservice', 'currencyservice', 'emailservice']

    // Define Snyk image and report path
    def snykImage = 'snyk/snyk-cli:latest'
    def reportDir = 'workspace/reports/snyk'
    sh "mkdir -p ${reportDir}"

    // Pull Snyk image once
    echo "[INFO] Pulling Snyk image..."
    sh "docker pull ${snykImage}"

    services.each { service ->
        def imageTag = "${service}:${env.BUILD_NUMBER}"
        def reportFile = "${reportDir}/${service}_snyk_report_${env.BUILD_NUMBER}.json"

        echo "[INFO] Scanning Docker image: ${imageTag}"

        sh """
            docker run --rm \
              -v /var/run/docker.sock:/var/run/docker.sock \
              -v /tmp:/tmp \
              ${snykImage} \
              test --docker ${imageTag} --all-projects --json > ${reportFile} || echo '[WARN] Scan failed for ${imageTag}'
        """

        echo "[INFO] Report for ${service} saved at ${reportFile}"
    }

    echo "[INFO] Archiving Snyk scan reports..."
    archiveArtifacts artifacts: "${reportDir}/*.json", allowEmptyArchive: true

    echo "[✔] All Snyk reports archived."
}

return [scanImagesWithSnyk: scanImagesWithSnyk]
