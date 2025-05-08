def setupWorkspace(String baseDir = 'workspace', List foldersToClean = ['logs', 'temp']) {
    echo "[INFO] Starting workspace cleanup in: ${baseDir}"

    foldersToClean.each { folder ->
        def fullPath = "${baseDir}/${folder}"
        echo "[INFO] Cleaning: ${fullPath}"
        try {
            sh "rm -rf '${fullPath}'"
            sh "mkdir -p '${fullPath}'"
            echo "[INFO] Recreated: ${fullPath}"
        } catch (Exception e) {
            echo "[ERROR] Failed to clean folder ${fullPath}: ${e.message}"
            throw e
        }
    }

    echo "[INFO] Workspace cleanup completed successfully."
}

return this
