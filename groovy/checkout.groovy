// groovy/checkout.groovy

def checkoutFromGit = {
    def branch = env.GIT_BRANCH
    def repoUrl = env.GIT_REPO_URL

    if (!branch?.trim()) {
        error "[ERROR] GIT_BRANCH is not set in the environment."
    }
    if (!repoUrl?.trim()) {
        error "[ERROR] GIT_REPO_URL is not set in the environment."
    }

    echo "[INFO] Starting Git checkout..."
    echo "[INFO] Branch: ${branch}"
    echo "[INFO] Repository: ${repoUrl}"

    checkout([
        $class: 'GitSCM',
        branches: [[name: "*/${branch}"]],
        userRemoteConfigs: [[url: repoUrl]]
    ])

    echo "[INFO] Git checkout completed successfully."
}

return [checkoutFromGit: checkoutFromGit]
