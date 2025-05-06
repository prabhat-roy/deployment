// workspace_cleanup_init.groovy

// Function to clean up the workspace
def cleanWorkspace() {
    echo "Cleaning up the workspace..."
    
    // Clean up the workspace by removing files and directories
    // This command will remove all files in the workspace
    deleteDir()
    
    echo "Workspace cleaned successfully"
}

def loadGlobalEnv() {
    echo "[INFO] Reading global.env..."

    def envFilePath = "${pwd()}/groovy/global.env"
    if (!fileExists(envFilePath)) {
        error("[ERROR] global.env not found at ${envFilePath}")
    }

    def envFile = readFile(envFilePath)
    envFile.split('\n').each { line ->
        line = line.trim()
        if (line && !line.startsWith('#')) {
            def (key, value) = line.split('=', 2).collect { it.trim() }
            if (key && value) {
                echo "[INFO] Setting ${key}=<masked>"
                // This sets the variable for current build
                env."${key}" = value
            }
        }
    }
}


// Function to combine the cleanup and Git initialization steps
def setupWorkspace() {
    cleanWorkspace()
    loadGlobalEnv()
}

// Call the setupWorkspace function to perform the cleanup and Git initialization
setupWorkspace()
