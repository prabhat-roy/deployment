def call() {
    echo "🛑 Stopping Clair service..."
    sh """
        docker stop clair || true
        docker rm clair || true
    """
}
