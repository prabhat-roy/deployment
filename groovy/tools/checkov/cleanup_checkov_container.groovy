// groovy/tools/checkov/cleanup_checkov_container.groovy
def cleanupCheckovContainer = {
    echo "🧹 Cleaning up Checkov Docker container..."
    // No additional cleanup action required in this case as Docker is cleaned up by 'docker run --rm'
}

return [cleanupCheckovContainer: cleanupCheckovContainer]
