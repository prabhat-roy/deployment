// groovy/Syft.groovy

def scanDockerImagesWithSyft = {
    try {
        echo "[INFO] Starting Syft SBOM generation..."

        // Define the list of microservices
        def services = ['frontend', 'recommendationservice', 'paymentservice', 'checkoutservice', 'shippingservice', 'cartservice', 'currencyservice', 'emailservice']

        // Docker image for Syft
        def syftImage = "anchore/syft:latest"

        // Directory to store reports
        def reportDir = 'workspace/reports/syft'
        sh "mkdir -p '${reportDir}'"

        // Pull the Syft image
        echo "[INFO] Pulling Syft Docker image..."
        sh "docker pull ${syftImage}"

        // Scan each service image
        services.each { service ->
            def imageTag = "${service}:${env.BUILD_NUMBER}"
            def reportFile = "${reportDir}/${service}_sbom_${env.BUILD_NUMBER}.json"

            echo "[INFO] Generating SBOM for ${imageTag} using Syft..."

            sh """
                docker run --rm \
                  -v /var/run/docker.sock:/var/run/docker.sock \
                  ${syftImage} ${imageTag} -o json > '${reportFile}' || echo '[WARN] SBOM generation failed for ${imageTag}'
            """

            echo "[INFO] SBOM saved at: ${reportFile}"
        }

        // Archive reports
        echo "[INFO] Archiving Syft SBOM reports..."
        archiveArtifacts artifacts: "${reportDir}/*.json", allowEmptyArchive: true

        echo "[✔] Syft SBOM generation completed successfully."
    } catch (Exception e) {
        echo "[ERROR] Syft scan failed: ${e.message}"
        throw e
    }
}

return [scanDockerImagesWithSyft: scanDockerImagesWithSyft]
