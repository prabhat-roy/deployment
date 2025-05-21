class EnvLoader implements Serializable {
    def steps

    EnvLoader(steps) {
        this.steps = steps
    }

    def loadEnvVars(String filePath = 'Jenkins.env') {
        def envVars = [:]

        try {
            if (!steps.fileExists(filePath)) {
                steps.echo "⚠️ Environment file '${filePath}' not found. Returning empty map."
                return envVars
            }

            steps.echo "📥 Loading environment variables from: ${filePath}"
            def lines = steps.readFile(filePath).readLines()

            lines.each { line ->
                line = line.trim()
                if (!line || line.startsWith('#')) {
                    return // Skip blank lines and comments
                }

                def parts = line.tokenize('=')
                if (parts.size() >= 2) {
                    def key = parts[0].trim()
                    def value = parts[1..-1].join('=').trim() // Handle '=' in value
                    envVars[key] = value
                    steps.echo "✅ Loaded: ${key}=${value}"
                } else {
                    steps.echo "⚠️ Skipped invalid line: ${line}"
                }
            }
        } catch (Exception e) {
            steps.echo "❌ Error loading env vars from ${filePath}: ${e.message}"
            throw e
        }

        return envVars
    }
}

// Instantiate the class and return the object
return new EnvLoader(this)
