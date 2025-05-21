def deleteDockerImages = {
    echo "[INFO] Deleting Docker images for specific deployments..."

    // Define the list of services (deployments)
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

    // Loop through each service and delete its associated Docker image
    services.each { service ->
        echo "[INFO] Deleting Docker image for service: ${service}"

        // Get the Docker image used by the deployment (based on the service)
        def image = sh(script: "kubectl get deployment ${service} -o jsonpath='{.spec.template.spec.containers[0].image}'", returnStdout: true).trim()

        if (image) {
            echo "[INFO] Found Docker image: ${image}. Deleting..."
            // Remove the Docker image locally
            sh "docker rmi ${image} || true"  // Ignore error if image is in use
        } else {
            echo "[WARN] No Docker image found for service: ${service}. Skipping..."
        }
    }

    echo "[INFO] Docker image cleanup completed."
}

return [deleteDockerImages: deleteDockerImages]
