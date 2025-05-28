class PuppetInstaller implements Serializable {
    def steps

    PuppetInstaller(steps) {
        this.steps = steps
    }

    void installPuppet() {
        steps.sh "chmod +x shell_script/install_puppet.sh"
        steps.sh "shell_script/install_puppet.sh"
    }
}

return new PuppetInstaller(this)
