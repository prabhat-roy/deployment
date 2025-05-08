// groovy/Cosign.groovy

def signDockerImage = { imageName ->
    try {
        echo "[INFO] Signing Docker image ${imageName} with Cosign..."

        // Sign the Docker image
        sh """
            cosign sign --key ${COSIGN_KEY} ${imageName}
        """

        echo "[INFO] Docker image ${imageName} signed successfully."
    } catch (Exception e) {
        echo "[ERROR] Failed to sign Docker image ${imageName}: ${e.message}"
        throw e  // Rethrow to fail the pipeline if the signing is critical
    }
}

return [signDockerImage: signDockerImage]
