def loadGlobalEnv() {
    echo "[INFO] Reading global.env..."
    def envFilePath = "${pwd()}/global.env"
    
    if (!fileExists(envFilePath)) {
        error("[ERROR] global.env not found at ${envFilePath}")
    }

    def envFile = readFile(envFilePath)
    def envVars = [:] // Use a map to collect the environment variables
    
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

    // Use withEnv to set environment variables for the pipeline
    withEnv(envVars.collect { "${it.key}=${it.value}" }) {
        echo "[INFO] Environment variables set successfully."
    }
}
