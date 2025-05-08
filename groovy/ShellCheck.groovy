// groovy/ShellCheckScan.groovy

def runShellCheck = {
    try {
        echo "[INFO] Starting ShellCheck scan..."

        // Ensure ShellCheck is installed (can use Docker image or install directly)
        docker.image('koalaman/shellcheck:stable').inside {
            // Run ShellCheck on the shell scripts
            sh 'shellcheck -o all *.sh'  // You can modify the pattern to match your shell script files

            // Archive the ShellCheck report
            archiveArtifacts allowEmptyArchive: true, artifacts: '**/shellcheck-report.txt', followSymlinks: false
        }

        echo "[INFO] ShellCheck scan completed and report archived."

    } catch (Exception e) {
        echo "[ERROR] ShellCheck scan failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if ShellCheck scan is critical
    }
}

return [runShellCheck: runShellCheck]