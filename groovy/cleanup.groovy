def setupWorkspace = {
    try {
        echo "[INFO] Starting workspace cleanup..."

        def foldersToClean = ['logs', 'temp']
        def baseDir = pwd()

        foldersToClean.each { folder ->
            def fullPath = "${baseDir}/${folder}"
            echo "[INFO] Cleaning: ${fullPath}"
            sh "rm -rf '${fullPath}'"
            sh "mkdir -p '${fullPath}'"
            echo "[INFO] Recreated: ${fullPath}"
        }

        echo "[INFO] Cleanup completed. groovy/ folder preserved."
    } catch (Exception e) {
        echo "[ERROR] Cleanup failed: ${e.message}"
        throw e
    }
}

return this
