def loadGlobalEnv = {
    echo "[INFO] Reading global.env..."
    def envFilePath = "${pwd()}/global.env"

    if (!fileExists(envFilePath)) {
        error("[ERROR] global.env not found at ${envFilePath}")
    }

    def envFile = readFile(envFilePath)
    def envVars = [:]

    envFile.split('\n').each { line ->
        line = line.trim()
        if (line && !line.startsWith('#')) {
            def (key, value) = line.split('=', 2).collect { it.trim() }
            if (key && value) {
                echo "[INFO] Setting ${key}=<masked>"
                envVars[key] = value
            }
        }
    }

    // Temporarily set variables in current context
    envVars.each { key, value ->
        env."${key}" = value
    }
}

// Return a map exposing the function
return [ loadGlobalEnv: loadGlobalEnv ]
