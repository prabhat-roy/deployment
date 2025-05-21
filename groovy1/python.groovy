def installPython() {
    // Make sure the shell script is executable
    sh "chmod +x shell_script/python.sh"

    // Call the shell script to install unzip
    sh "shell_script/python.sh"
}

return this
