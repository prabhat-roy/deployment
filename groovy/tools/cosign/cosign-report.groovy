def generateCosignReport() {
    echo "📋 Generating Cosign report..."
    // Set environment variables from cosign.env
    sh 'source cosign/cosign.env'

    // Example report generation command
    sh """
        cosign verify --key $COSIGN_PUBLIC_KEY_PATH $COSIGN_REPO > $COSIGN_REPORT_FILE
    """
    echo "✅ Report generated: $COSIGN_REPORT_FILE"
}
