def call(String envFilePath = 'groovy/Deployment.env') {
    def envVars = [:]

    echo "[INFO] Loading environment variables from: ${envFilePath}"

    // Check if the file exists
    if (!fileExists(envFilePath)) {
        error "[ERROR] Environment file not found at: ${envFilePath}"
    }

    // Read file contents
    def lines = readFile(envFilePath).split('\n')
    lines.each { line ->
        line = line.trim()
        if (line && !line.startsWith("#")) {
            // Regex to match key=value pairs
            def matcher = line =~ /^\s*([\w.-]+)\s*=\s*(.*)\s*$/ 
            if (matcher.matches()) {
                def key = matcher[0][1].trim()
                def value = matcher[0][2].trim()

                // Remove surrounding quotes if present
                if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
                    value = value.substring(1, value.length() - 1)
                }

                envVars[key] = value
                echo "[DEBUG] Loaded env var: ${key}=****"  // Log key, but mask value for security
            } else {
                echo "[DEBUG] Skipping invalid line: ${line}"
            }
        }
    }

    // Ensure envVars is not empty before returning
    if (envVars.isEmpty()) {
        error "[ERROR] No valid environment variables found in the file"
    }

    return envVars
}
