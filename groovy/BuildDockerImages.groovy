def buildDockerImages = {
    echo "[INFO] Starting Docker image build process..."

    // List of microservices to build
    def services = ['frontend', 'recommendationservice', 'paymentservice', 'checkoutservice', 'shippingservice', 'cartservice', 'currencyservice', 'emailservice']
    
    // Loop through each service to build the Docker image
    services.each { service ->
        echo "[INFO] Building Docker image for ${service} with tag ${env.BUILD_NUMBER}"

        // Build Docker image for each service using the Jenkins build number as the tag
        sh """
            docker build -t ${service}:${env.BUILD_NUMBER} ./src/${service}
        """
        echo "[INFO] Docker image ${service}:${env.BUILD_NUMBER} built successfully."
    }

    echo "[INFO] Docker images built for all services."
}

return [buildDockerImages: buildDockerImages]
