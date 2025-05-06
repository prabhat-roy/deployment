def call() {
    echo "🚀 Starting Clair service (detached)..."
    sh """
        docker run -d --name clair \
        -p 6060:6060 -p 6061:6061 \
        ${env.CLAIR_IMAGE}
    """
    sleep 10 // Give Clair time to initialize
}
