class NodejsInstaller implements Serializable {
    def steps

    NodejsInstaller(steps) {
        this.steps = steps
    }

    void installNodejs() {
        steps.sh "chmod +x shell_script/install_nodejs.sh"
        steps.sh "shell_script/install_nodejs.sh"
    }
}

return new NodejsInstaller(this)
