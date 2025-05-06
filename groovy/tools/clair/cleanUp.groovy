def call() {
    echo "🧹 Cleaning up Clair scan artifacts..."
    sh "rm -f image.tar ${env.CLAIR_OUTPUT}"
}
