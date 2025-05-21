// Method to update environment variables in Jenkins.env file
def updateEnvFile(String key, String value) {
    def envFile = 'Jenkins.env'

    // Check if the env file exists
    if (fileExists(envFile)) {
        // Read the content of the Jenkins.env file
        def lines = readFile(envFile).readLines()
        def updated = false

        // Update the key if it exists in the file
        lines = lines.collect { line ->
            if (line.startsWith("${key}=")) {
                updated = true
                return "${key}=${value}"  // Update the key with the new value
            }
            return line  // Keep other lines as they are
        }

        // If the key wasn't found, add the key-value pair to the end
        if (!updated) {
            lines.add("${key}=${value}")
        }

        // Write the updated lines back to the Jenkins.env file
        writeFile file: envFile, text: lines.join('\n') + '\n'
    } else {
        // If the file doesn't exist, create it with the key-value pair
        writeFile file: envFile, text: "${key}=${value}\n"
    }

    // Log the update
    echo "✅ ${key} saved to Jenkins.env with value: ${value}"
}

// Method to load environment variables from Jenkins.env file
def loadEnvVars(String filePath) {
    def envVars = [:]

    if (!fileExists(filePath)) {
        echo "⚠️  ${filePath} not found!"
        return envVars
    }

    readFile(filePath).readLines().each { line ->
        line = line.trim()
        if (line && !line.startsWith('#') && line.contains('=')) {
            def parts = line.split('=', 2)
            envVars[parts[0]] = parts[1]
        }
    }

    return envVars
}

// Return this to make methods accessible when loaded
return this
