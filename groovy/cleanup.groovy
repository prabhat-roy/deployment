def installCloudCLI() {
    def cloudProvider = env.CLOUD_PROVIDER

    if (!cloudProvider?.trim()) {
        def props = new Properties()
        new File('cloud.env').withInputStream { props.load(it) }
        cloudProvider = props.getProperty('CLOUD_PROVIDER')
    }

    println "Detected cloud provider: ${cloudProvider}"

    // Make the shell script executable
    sh "chmod +x shell_script/cloud_cli.sh"

    // Call the shell script with the cloud provider
    sh "shell_script/cloud_cli.sh ${cloudProvider}"
}

return this
