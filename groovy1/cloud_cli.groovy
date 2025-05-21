def installCloudCLI() {
    // Make sure the shell script is executable
    sh "chmod +x shell_script/cloud_cli.sh"

    // Call the shell script to install cloudcli
    sh "shell_script/cloud_cli.sh ${env.CLOUD_PROVIDER}"
}

return this
