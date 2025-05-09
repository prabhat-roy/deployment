def installCloudCLI() {
    def cloudProvider = env.CLOUD_PROVIDER

    if (!cloudProvider?.trim()) {
        def props = new Properties()
        new File('cloud.env').withInputStream { props.load(it) }
        cloudProvider = props.getProperty('CLOUD_PROVIDER')
    }

    println "Detected cloud provider: ${cloudProvider}"
    
    // Call shell script with provider name
    sh "bash shell_script/cloud_cli.sh ${cloudProvider}"
}
return this
