def installDocker() {
    // Make sure the shell script is executable
    sh "chmod +x shell_script/install_docker.sh"

    // Call the shell script to install docker
    sh "shell_script/install_docker.sh"
}

return this
