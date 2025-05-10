def installNodejs() {
    // Make sure the shell script is executable
    sh "chmod +x shell_script/nodejs.sh"

    // Call the shell script to install unzip
    sh "shell_script/nodejs.sh"
}

return this
