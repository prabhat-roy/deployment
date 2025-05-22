class WgetInstaller implements Serializable {
    def steps

    WgetInstaller(steps) {
        this.steps = steps
    }

    void installWget() {
        steps.sh "chmod +x shell_script/install_wget.sh"
        steps.sh "shell_script/install_wget.sh"
    }
}

return new WgetInstaller(this)
