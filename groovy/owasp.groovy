def installOwasp() {
    // Make sure the shell script is executable
    sh "chmod +x shell_script/owasp.sh"

    // Call the shell script to install uowasp
    sh "sudo shell_script/owasp.sh"
}

return this
