// groovy/LoadEnvVars.groovy

// Define the function to load environment variables from the file
def loadEnvVars(String envFilePath) {
    def envVars = [:]

 //   echo "[INFO] Loading environment variables from: ${envFilePath}"

    // Check if the file exists
    if (!fileExists(envFilePath)) {
        error "[ERROR] Environment file not found at: ${envFilePath}"
    }

    // Read the file and split it into lines
    def lines = readFile(envFilePath).split('\n')
    lines.each { line ->
        line = line.trim()

        // Skip empty lines or comments
        if (line && !line.startsWith("#")) {
            // Match the key-value pair in the format KEY=VALUE
            def matcher = line =~ /^\s*([\w.-]+)\s*=\s*(.*)\s*$/
            if (matcher.matches()) {
                def key = matcher[0][1].trim()
                def value = matcher[0][2].trim()

                // Remove surrounding quotes if present
                if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
                    value = value.substring(1, value.length() - 1)
                }

                // Store the key-value pair in the map
                envVars[key] = value
//                echo "[INFO] Loaded env var: ${key}=****"  // Don't log the actual value for security
            }
        }
    }

    return envVars
}

// Return the function so it can be called from the Jenkinsfile
return this
