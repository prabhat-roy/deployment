// groovy/tools/checkov/load_checkov_env.groovy
def loadCheckovEnv = {
    echo "📄 Loading Checkov environment variables..."

    // Reading the checkov.env file
    def envFile = readFile 'groovy/tools/checkov/checkov.env'
    def checkovEnvVars = [:]  // Initialize an empty map for environment variables
    
    envFile.split("\n").each { line ->
        if (line.trim() && line.trim().startsWith("export ")) {
            def (key, value) = line.replace("export ", "").split("=", 2)
            checkovEnvVars[key.trim()] = value.trim().replaceAll('"', '')
        }
    }

    // Set the environment variables in Jenkins
    return checkovEnvVars
}

return [loadCheckovEnv: loadCheckovEnv]
