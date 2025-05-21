// env_writer.groovy
// ------------------
// Shared library script to write or update environment variables in a file (e.g., Jenkins.env)

def writeEnvVar(String key, String value, String filePath = 'Jenkins.env') {
    try {
        echo "🔧 Writing environment variable: ${key}=${value} to ${filePath}"

        def updated = false
        def lines = []

        // If the env file exists, read and update it
        if (fileExists(filePath)) {
            lines = readFile(filePath).readLines()
            lines = lines.collect { line ->
                if (line.startsWith("${key}=")) {
                    updated = true
                    return "${key}=${value}"  // Replace existing line
                }
                return line  // Keep other lines unchanged
            }
        }

        // If the key was not found, add it
        if (!updated) {
            lines.add("${key}=${value}")
        }

        // Write final content back to file
        writeFile file: filePath, text: lines.join('\n') + '\n'
        echo "✅ Environment variable ${key} set to ${value}"
    } catch (Exception e) {
        echo "❌ Error writing env var ${key}: ${e.message}"
        throw e  // Rethrow to fail the stage if needed
    }
}

// Optional method: write multiple key-values from a map
def writeEnvVars(Map<String, String> kvPairs, String filePath = 'Jenkins.env') {
    kvPairs.each { key, value ->
        writeEnvVar(key, value, filePath)
    }
}

// Return this script for usage in Jenkinsfile
return this
