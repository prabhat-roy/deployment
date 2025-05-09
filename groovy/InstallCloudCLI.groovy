def installCloudCLI() {
    def cloudProvider = env.CLOUD_PROVIDER

    if (!cloudProvider?.trim()) {
        def props = new Properties()
        new File('cloud.env').withInputStream { props.load(it) }
        cloudProvider = props.getProperty('CLOUD_PROVIDER')
    }

    println "Installing CLI for cloud provider: ${cloudProvider}"

    switch(cloudProvider?.toUpperCase()) {
        case 'AWS':
            sh '''
                curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                unzip -q awscliv2.zip
                sudo ./aws/install
                aws --version
            '''
            break
        case 'GCP':
            sh '''
                curl -sSL https://sdk.cloud.google.com | bash
                source $HOME/google-cloud-sdk/path.bash.inc
                gcloud --version
            '''
            break
        case 'AZURE':
            sh '''
                curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
                az version
            '''
            break
        default:
            error("Unknown cloud provider: ${cloudProvider}. CLI installation skipped.")
    }
}
return this
