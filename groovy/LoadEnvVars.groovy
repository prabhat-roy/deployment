// groovy/loadEnvVars.groovy

def call(String envFilePath = 'groovy/deployment.env') {
    def envVars = [:]

    echo "[INFO] Loading environment variables from: ${envFilePath}"

    if (!fileExists(envFilePath)) {
        error "[ERROR] Environment file not found at: ${envFilePath}"
    }

    def lines = readFile(envFilePath).split('\n')
    lines.each { line ->
        line = line.trim()
        if (line && !line.startsWith("#")) {
            def matcher = line =~ /^\s*([\w.-]+)\s*=\s*(.*)\s*$/
            if (matcher.matches()) {
                def key = matcher[0][1].trim()
                def value = matcher[0][2].trim()
                // Remove surrounding quotes if present
                if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
                    value = value.substring(1, value.length() - 1)
                }
                envVars[key] = value
                echo "[DEBUG] Loaded env var: ${key}=****"
            }
        }
    }

    return envVars
}
