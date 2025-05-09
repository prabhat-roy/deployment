def installCurl() {
    // Make sure the shell script is executable
    sh "chmod +x shell_script/curl.sh"

    // Call the shell script to install unzip
    sh "shell_script/curl.sh"
}

return this
