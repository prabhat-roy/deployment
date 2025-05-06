// groovy/cleanup.groovy
def setupWorkspace = {
    echo "[INFO] Cleaning up build folders only..."
    sh 'rm -rf workspace/logs workspace/temp'
    echo "[INFO] Cleaned folders, but kept groovy scripts intact."

    echo "[INFO] Recreating folder structure..."
    sh 'mkdir -p workspace/logs workspace/temp'
}

return [setupWorkspace: setupWorkspace]
