def loadGlobalEnv() {
    echo "[INFO] Reading global.env..."
    def envFilePath = "${pwd()}/global.env"
    if (!fileExists(envFilePath)) {
        error("[ERROR] global.env not found at ${envFilePath}")
    }

    def envFile = readFile(envFilePath)
    envFile.split('\n').each { line ->
        line = line.trim()
        if (line && !line.startsWith('#')) {
            def (key, value) = line.split('=', 2).collect { it.trim() }
            if (key && value) {
                echo "[INFO] Setting ${key}=<masked>"
                env."${key}" = value
            }
        }
    }
}
