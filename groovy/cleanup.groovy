// cleanup.groovy
// This script will clean up the workspace and create necessary folders.

def cleanupWorkspace = {
    echo "[INFO] Cleaning up the workspace..."
    deleteDir()  // Deletes all files in the workspace to start fresh
    echo "[INFO] Workspace cleaned successfully."

    echo "[INFO] Recreating necessary folders..."
    sh 'mkdir -p workspace/logs workspace/temp'  // Create required folder structure
    echo "[INFO] Folder structure created successfully."
}

return [cleanupWorkspace: cleanupWorkspace]
