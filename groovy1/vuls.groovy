// groovy/Vuls.groovy

def scanWithVuls = {
    echo "[INFO] Starting Docker image scanning with Vuls..."

    // List of services to scan
    def services = ['frontend', 'recommendationservice', 'paymentservice', 'checkoutservice', 'shippingservice', 'cartservice', 'currencyservice', 'emailservice']

    // Vuls Docker Image
    def vulsDockerImage = 'fullhunt/vuls'  // Ensure you're using the correct Vuls image version

    // Report directory
    def reportDir = 'workspace/reports/vuls-reports'
    sh "mkdir -p ${reportDir}"

    // Loop through each service and scan the corresponding Docker image with Vuls
    services.each { service ->
        def dockerImage = "${service}:${env.BUILD_NUMBER}"
        def reportFile = "${reportDir}/vuls-report-${service}_${env.BUILD_NUMBER}.txt"
        
        echo "[INFO] Running Vuls scan on Docker image ${dockerImage}..."

        // Run Vuls scan on the Docker image
        sh """
            docker pull ${dockerImage}
            docker run --rm -v /var/run/docker.sock:/var/run/docker.sock ${vulsDockerImage} \
                vuls scan --docker ${dockerImage} > ${reportFile}
        """

        // Archive the scan report
        echo "[INFO] Archiving Vuls scan report for ${dockerImage}..."
        archiveArtifacts artifacts: "${reportFile}", allowEmptyArchive: true
    }

    echo "[INFO] Docker image scanning with Vuls completed for all images."
}

return [scanWithVuls: scanWithVuls]
