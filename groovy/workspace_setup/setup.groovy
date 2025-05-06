// workspace_cleanup_init.groovy

// Function to clean up the workspace
def cleanWorkspace() {
    echo "Cleaning up the workspace..."
    
    // Clean up the workspace by removing files and directories
    // This command will remove all files in the workspace
    deleteDir()
    
    echo "Workspace cleaned successfully"
}

// Function to initialize the Git repository
def initializeGitRepository() {
    echo "Initializing Git repository..."
    
    // Run Git init and checkout
    sh 'git init'
    sh 'git checkout main'  // You can change 'main' to any branch you want
    
    echo "Git repository initialized successfully"
}

// Function to combine the cleanup and Git initialization steps
def setupWorkspace() {
    cleanWorkspace()
    initializeGitRepository()
}

// Call the setupWorkspace function to perform the cleanup and Git initialization
setupWorkspace()
