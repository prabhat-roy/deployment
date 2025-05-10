def installWget() {
    // Make sure the shell script is executable
    sh "chmod +x shell_script/wget.sh"

    // Call the shell script to install unzip
    sh "shell_script/wget.sh"
}

return this
