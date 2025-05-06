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

return [checkoutFromGit: checkoutFromGit]
