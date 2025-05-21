def installTerraform() {
    // Make sure the shell script is executable
    sh "chmod +x shell_script/terraform.sh"

    // Call the shell script to install unzip
    sh "shell_script/terraform.sh"
}

return this
