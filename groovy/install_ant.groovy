class AntInstaller implements Serializable {
    def steps

    AntInstaller(steps) {
        this.steps = steps
    }

    void installAnt() {
        steps.sh "chmod +x shell_script/install_ant.sh"
        steps.sh "shell_script/install_ant.sh"
    }
}

return new AntInstaller(this)
