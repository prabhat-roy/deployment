def installKubernetes() {
    // Make sure the shell script is executable
    sh "chmod +x shell_script/kubernetes.sh"

    // Call the shell script to install unzip
    sh "shell_script/kubernetes.sh"
}

return this
