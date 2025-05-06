def cosignQuit() {
    echo "🧹 Cleaning up Cosign-related files and processes..."
    // Clean up any temporary files
    sh 'rm -rf /tmp/cosign'
    echo "✅ Cleanup completed."
}
