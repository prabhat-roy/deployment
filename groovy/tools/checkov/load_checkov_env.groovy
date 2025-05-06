// groovy/tools/checkov/load_checkov_env.groovy

def loadCheckovEnv() {
    echo "📄 Loading Checkov environment variables..."
    def envFile = readFile 'groovy/tools/checkov/checkov.env'
    def envVars = [:]  // Create an empty map to store environment variables

    envFile.split("\n").each { line ->
        if (line.trim() && line.trim().startsWith("export ")) {
            def (key, value) = line.replace("export ", "").split("=", 2)
            envVars[key.trim()] = value.trim().replaceAll('"', '')
        }
    }

    return envVars  // Return the map containing environment variables
}


return [loadCheckovEnv: loadCheckovEnv]
