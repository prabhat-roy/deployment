def installDocker() {
    // Make sure the shell script is executable
    sh "chmod +x shell_script/docker.sh"

    // Call the shell script to install unzip
    sh "shell_script/docker.sh"
}

return this
