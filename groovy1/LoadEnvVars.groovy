// EnvLoader.groovy
def loadEnvVars(String envFilePath = 'Jenkins.env') {
    def envVars = [:]

    echo "[INFO] Loading env vars from: ${envFilePath}"

    if (!fileExists(envFilePath)) {
        error "[ERROR] File not found: ${envFilePath}"
    }

    def lines = readFile(envFilePath).split('\n')
    lines.each { line ->
        line = line.trim()
        if (line && !line.startsWith("#")) {
            def matcher = line =~ /^\s*([\w.-]+)\s*=\s*(.*)\s*$/
            if (matcher.matches()) {
                def key = matcher[0][1].trim()
                def value = matcher[0][2].trim()
                
                // Remove quotes around values if they exist
                if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
                    value = value.substring(1, value.length() - 1)
                }

                // Instead of putAt, use this safer syntax
                envVars[key] = value
            }
        }
    }

    return envVars
}

return this
