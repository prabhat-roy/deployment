def installCloudCLI() {
    // Make sure the shell script is executable
    sh "chmod +x shell_script/cloudcli.sh"

    // Call the shell script to install unzip
    sh "shell_script/cloudcli.sh"
}

return this
