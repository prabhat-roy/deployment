def setupWorkspace() {
    try {
        echo "[INFO] Starting cleanup of build folders..."

        def baseDir = 'workspace'
        def foldersToClean = ['logs', 'temp']

        foldersToClean.each { folder ->
            def fullPath = "${baseDir}/${folder}"
            echo "[INFO] Cleaning folder: ${fullPath}"
            sh "rm -rf '${fullPath}'"
            sh "mkdir -p '${fullPath}'"
            echo "[INFO] Recreated folder: ${fullPath}"
        }

        echo "[INFO] Workspace cleanup and structure recreation completed successfully."
    } catch (Exception e) {
        echo "[ERROR] Failed to clean workspace: ${e.message}"
        throw e
    }
}

return this
