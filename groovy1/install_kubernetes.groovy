def installKubernetes() {
    // Make sure the shell script is executable
    sh "chmod +x shell_script/install_kubernetes.sh"

    // Call the shell script to install kubernetes
    sh "shell_script/install_kubernetes.sh"
}

return this
