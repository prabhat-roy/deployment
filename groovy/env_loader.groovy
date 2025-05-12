// env_loader.groovy
// ------------------
// Shared library to load environment variables from a file into a pipeline Map

def loadEnvVars(String filePath = 'Jenkins.env') {
    def envVars = [:]

    try {
        if (!fileExists(filePath)) {
            echo "⚠️ Environment file '${filePath}' not found. Returning empty map."
            return envVars
        }

        echo "📥 Loading environment variables from: ${filePath}"
        def lines = readFile(filePath).readLines()

        lines.each { line ->
            line = line.trim()
            if (!line || line.startsWith('#')) {
                return // Skip blank lines and comments
            }

            def parts = line.tokenize('=')
            if (parts.size() >= 2) {
                def key = parts[0].trim()
                def value = parts[1..-1].join('=').trim() // Handle cases where value contains '='
                envVars[key] = value
                echo "✅ Loaded: ${key}=${value}"
            } else {
                echo "⚠️ Skipped invalid line: ${line}"
            }
        }
    } catch (Exception e) {
        echo "❌ Error loading env vars from ${filePath}: ${e.message}"
        throw e
    }

    return envVars
}

// Return script object
return this
