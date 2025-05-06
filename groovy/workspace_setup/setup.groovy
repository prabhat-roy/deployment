def setupWorkspace = {
    echo "[INFO] Cleaning up the workspace..."
    deleteDir()
    echo "[INFO] Workspace cleaned successfully."

    echo "[INFO] Recreating necessary folders..."
    sh 'mkdir -p workspace/logs workspace/temp'
    echo "[INFO] Folder structure created successfully."
}

return [setupWorkspace: setupWorkspace]
