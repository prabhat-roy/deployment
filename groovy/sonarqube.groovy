def installSonarqube() {
    // Make sure the shell script is executable
    sh "chmod +x shell_script/sonarqube.sh"

    // Call the shell script to install unzip
    sh "shell_script/sonarqube.sh"
}

return this
