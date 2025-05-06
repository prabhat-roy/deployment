def setupWorkspace = {
    echo "[INFO] Cleaning up the workspace..."

    // Clean everything in the current workspace
    deleteDir()
    echo "[INFO] Workspace cleaned successfully."

    // Optional: recreate known subdirectories
    def directoriesToCreate = ['artifacts', 'logs', 'tmp']
    directoriesToCreate.each { dirName ->
        new File("${pwd()}/${dirName}").mkdirs()
        echo "[INFO] Created directory: ${dirName}"
    }

    // Optional: git init (if needed for testing)
    // sh "git init && git checkout -b main"

    echo "[INFO] Workspace setup completed."
}
return [setupWorkspace: setupWorkspace]
