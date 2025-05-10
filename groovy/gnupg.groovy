def installGnupg() {
    // Make sure the shell script is executable
    sh "chmod +x shell_script/gnupg.sh"

    // Call the shell script to install unzip
    sh "shell_script/gnupg.sh"
}

return this
