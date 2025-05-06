// groovy/checkout.groovy
def checkoutFromGit = { String branch, String repoUrl ->
    echo "[INFO] Checking out from Git repository..."

    checkout([$class: 'GitSCM',
              branches: [[name: "*/${branch}"]],
              userRemoteConfigs: [[url: repoUrl]]])

    echo "[INFO] Checkout from Git repository completed successfully."
}

return [checkoutFromGit: checkoutFromGit]
