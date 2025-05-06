def cosignSignImage() {
    echo "🔐 Signing the Docker image with Cosign..."
    // Set environment variables from checkov.env
    sh 'source cosign/cosign.env'

    // Run the Cosign signing command
    sh """
        cosign sign --key $COSIGN_KEY_PATH $COSIGN_REPO
    """
    echo "✅ Image signed successfully with Cosign."
}
