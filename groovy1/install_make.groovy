class MakeInstaller implements Serializable {
    def steps

    MakeInstaller(steps) {
        this.steps = steps
    }

    void installMake() {
        steps.sh "chmod +x shell_script/install_make.sh"
        steps.sh "shell_script/install_make.sh"
    }
}

return new MakeInstaller(this)
