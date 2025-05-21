def loadGlobalEnv = {
    echo "[INFO] Loading global environment variables..."

    def envContent = readFile 'groovy/global.env'
    def envList = []

    envContent.split('\n').each { line ->
        line = line.trim()
        if (line && !line.startsWith("#")) {
            def (key, value) = line.tokenize('=')
            if (key && value) {
                def entry = "${key.trim()}=${value.trim()}"
                envList.add(entry)
                echo "[DEBUG] Parsed: ${entry}"
            }
        }
    }

    return envList
}

return [loadGlobalEnv: loadGlobalEnv]
