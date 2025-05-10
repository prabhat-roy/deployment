def installGo() {
    // Make sure the shell script is executable
    sh "chmod +x shell_script/go.sh"

    // Call the shell script to install go
    sh "shell_script/go.sh"
}

return this
