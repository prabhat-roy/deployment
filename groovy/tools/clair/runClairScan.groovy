def call() {
    echo "🔍 Running Clair scan on image: ${env.CLAIR_SCAN_IMAGE}"

    sh """
        docker pull ${env.CLAIR_SCAN_IMAGE}

        docker save ${env.CLAIR_SCAN_IMAGE} -o image.tar

        docker run --rm -v \$(pwd):/scan -e CLAIR_ADDR=${env.CLAIR_HOST} \
            ghcr.io/arminc/clair-scanner:latest \
            --ip 127.0.0.1 \
            --report /scan/${env.CLAIR_OUTPUT} \
            image.tar || true
    """
}
