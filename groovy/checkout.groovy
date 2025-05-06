// checkout.groovy
// This script will handle the Git checkout process.

def checkoutFromGit = { String branch, String repoUrl ->
    echo "[INFO] Checking out from Git repository..."

    // Perform Git checkout using the provided branch and repository URL
    checkout([$class: 'GitSCM',
              branches: [[name: "*/${branch}"]], 
              userRemoteConfigs: [[url: repoUrl]]])

    echo "[INFO] Checkout from Git repository completed successfully."
}

def loadGlobalEnv = {
    echo "[INFO] Reading global.env..."
    def envFilePath = "groovy/global.env"

    if (!fileExists(envFilePath)) {
        error("[ERROR] global.env not found at ${envFilePath}")
    }

    def envFile = readFile(envFilePath)
    def envVars = [:]

    envFile.split('\n').each { line ->
        line = line.trim()
        if (line && !line.startsWith('#')) {
            def (key, value) = line.split('=', 2).collect { it.trim() }
            if (key && value) {
                echo "[INFO] Setting ${key}=<masked>"
                envVars[key] = value
            }
        }
    }

    // Temporarily set variables in the current context
    envVars.each { key, value ->
        env."${key}" = value
    }
}

// Return a map exposing the functions
return [checkoutFromGit: checkoutFromGit, loadGlobalEnv: loadGlobalEnv]
