def call() {
    echo "🚀 Running Checkov scan..."
    sh """
        docker run --rm \
            -v \$(pwd):/tf \
            ${env.CHECKOV_IMAGE} \
            -d ${env.CHECKOV_TARGET_PATH} \
            ${env.CHECKOV_OPTIONS} \
            --output ${env.CHECKOV_OUTPUT} \
            --soft-fail ${env.CHECKOV_SOFT_FAIL} \
            --output-file /tf/${env.REPORT_FILE}
    """
}
