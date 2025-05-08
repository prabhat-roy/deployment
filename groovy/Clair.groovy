// groovy/clairScan.groovy

def scanWithClair = {
    echo "[INFO] Starting Docker image scanning with Clair..."

    // List of services to scan
    def services = ['frontend', 'recommendationservice', 'paymentservice', 'checkoutservice', 'shippingservice', 'cartservice', 'currencyservice', 'emailservice']

    // Clair Docker Image (Ensure you have the correct image tag for your Clair version)
    def clairDockerImage = 'quay.io/coreos/clair:v4.0.0'  // Update with your Clair image name and version

    // Directory for storing scan reports
    def reportDir = 'workspace/logs/clair-reports'
    sh "mkdir -p ${reportDir}"

    // Loop through each service and scan the corresponding Docker image with Clair
    services.each { service ->
        def dockerImage = "${service}:${env.BUILD_NUMBER}"
        echo "[INFO] Pulling Clair Docker image..."

        // Pull the Clair Docker image
        sh """
            docker pull ${clairDockerImage}
        """

        echo "[INFO] Running Clair scan on Docker image ${dockerImage}..."
        
        // Generate a report file for each service
        def reportFile = "${reportDir}/clair-report-${service}_${env.BUILD_NUMBER}.json"
        
        // Run Clair scan on the Docker image
        sh """
            docker run --rm -v /tmp:/tmp ${clairDockerImage} \
                clair-scanner --local-scanner --image ${dockerImage} > ${reportFile}
        """

        // Archive the scan report
        echo "[INFO] Archiving Clair scan report for ${dockerImage}..."
        archiveArtifacts artifacts: "${reportFile}", allowEmptyArchive: true
    }

    echo "[INFO] Docker image scanning with Clair completed for all images."
}

return [scanWithClair: scanWithClair]
