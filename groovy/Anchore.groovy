// groovy/Anchore.groovy

def scanWithAnchore = {
    echo "[INFO] Starting Docker image scanning with Anchore..."

    // List of services to scan
    def services = ['frontend', 'recommendationservice', 'paymentservice', 'checkoutservice', 'shippingservice', 'cartservice', 'currencyservice', 'emailservice']

    // Anchore Docker Image
    def anchoreDockerImage = 'anchore/anchore-engine:latest'  // Ensure you use the correct Anchore image version

    // Report directory
    def reportDir = 'workspace/reports/anchore-reports'
    sh "mkdir -p ${reportDir}"

    // Loop through each service and scan the corresponding Docker image with Anchore
    services.each { service ->
        def dockerImage = "${service}:${env.BUILD_NUMBER}"
        def reportFile = "${reportDir}/anchore-report-${service}_${env.BUILD_NUMBER}.json"
        
        echo "[INFO] Running Anchore scan on Docker image ${dockerImage}..."

        // Run Anchore scan on the Docker image
        sh """
            docker pull ${dockerImage}
            docker run --rm -v /var/run/docker.sock:/var/run/docker.sock ${anchoreDockerImage} \
                anchore-cli image add ${dockerImage} \
                && anchore-cli image scan ${dockerImage} \
                && anchore-cli image wait ${dockerImage} \
                > ${reportFile}
        """

        // Archive the scan report
        echo "[INFO] Archiving Anchore scan report for ${dockerImage}..."
        archiveArtifacts artifacts: "${reportFile}", allowEmptyArchive: true
    }

    echo "[INFO] Docker image scanning with Anchore completed for all images."
}

return [scanWithAnchore: scanWithAnchore]
