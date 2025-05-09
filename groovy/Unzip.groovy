def installUnzip() {
    // Make sure the shell script is executable
    sh "chmod +x shell_script/Unzip.sh"

    // Call the shell script to install unzip
    sh "shell_script/Unzip.sh"
}

return this
