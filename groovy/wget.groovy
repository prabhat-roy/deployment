def installWget() {
    // Make sure the shell script is executable
    sh "chmod +x shell_script/wget.sh"

    // Call the shell script to install wget
    sh "shell_script/wget.sh"
}

return this
