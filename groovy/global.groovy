def loadGlobalEnv = {
    echo "[INFO] Loading global environment variables..."

    def envContent = readFile 'groovy/global.env'
    def props = [:]

    envContent.split('\n').each { line ->
        line = line.trim()
        if (line && !line.startsWith("#")) {
            def (key, value) = line.tokenize('=')
            if (key && value) {
                props[key.trim()] = value.trim()
                // Also set it to environment dynamically
                env[key.trim()] = value.trim()
                echo "[DEBUG] Loaded: ${key.trim()}=${value.trim()}"
            }
        }
    }

    echo "[INFO] Global environment variables loaded successfully."
}

return [loadGlobalEnv: loadGlobalEnv]
