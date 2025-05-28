class CloudCLIInstaller implements Serializable {
    def steps

    CloudCLIInstaller(steps) {
        this.steps = steps
    }

    void installCloudCLI() {
        steps.sh "chmod +x shell_script/install_cloud_cli.sh"
        steps.sh "shell_script/install_cloud_cli.sh ${steps.env.CLOUD_PROVIDER}"
    }
}

return new CloudCLIInstaller(this)
