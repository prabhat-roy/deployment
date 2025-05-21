def installMake() {
    // Make sure the shell script is executable
    sh "chmod +x shell_script/make.sh"

    // Call the shell script to install unzip
    sh "shell_script/make.sh"
}

return this
