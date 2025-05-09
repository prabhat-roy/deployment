def installUnzip() {
    // Make sure the shell script is executable
    sh "chmod +x shell_script/unzip.sh"

    // Call the shell script to install unzip
    sh "shell_script/unzip.sh"
}

return this
