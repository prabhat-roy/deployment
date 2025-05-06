def cosignVerifyImage() {
    echo "🔍 Verifying the Docker image signature with Cosign..."
    // Set environment variables from cosign.env
    sh 'source cosign/cosign.env'

    // Run the Cosign verification command
    sh """
        cosign verify --key $COSIGN_PUBLIC_KEY_PATH $COSIGN_REPO
    """
    echo "✅ Image signature verified successfully."
}
