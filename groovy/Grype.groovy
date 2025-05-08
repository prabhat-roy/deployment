def scanDockerImagesWithGrype = {
    echo "[INFO] Starting Docker image scan process with Grype..."

    // Define microservices
    def services = ['frontend', 'recommendationservice', 'paymentservice', 'checkoutservice', 'shippingservice', 'cartservice', 'currencyservice', 'emailservice']

    // Define Grype image and report path
    def grypeImage = 'anchore/grype:latest'
    def reportDir = 'workspace/reports/grype'
    sh "mkdir -p ${reportDir}"

    // Pull Grype image once
    echo "[INFO] Pulling Grype scanner image..."
    sh "docker pull ${grypeImage}"

    services.each { service ->
        def imageTag = "${service}:${env.BUILD_NUMBER}"
        def reportFile = "${reportDir}/${service}_grype_report_${env.BUILD_NUMBER}.json"

        echo "[INFO] Scanning Docker image: ${imageTag}"

        sh """
            docker run --rm \
              -v /var/run/docker.sock:/var/run/docker.sock \
              -v /tmp:/tmp \
              ${grypeImage} \
              ${imageTag} -o json > ${reportFile} || echo '[WARN] Scan failed for ${imageTag}'
        """

        echo "[INFO] Report for ${service} saved at ${reportFile}"
    }

    echo "[INFO] Archiving Grype scan reports..."
    archiveArtifacts artifacts: "${reportDir}/*.json", allowEmptyArchive: true

    echo "[✔] All Grype reports archived."
}

return [scanDockerImagesWithGrype: scanDockerImagesWithGrype]
