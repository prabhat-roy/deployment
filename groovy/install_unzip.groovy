class UnzipInstaller implements Serializable {
    def steps

    UnzipInstaller(steps) {
        this.steps = steps
    }

    void installUnzip() {
        steps.sh "chmod +x shell_script/install_unzip.sh"
        steps.sh "shell_script/install_unzip.sh"
    }
}

return new UnzipInstaller(this)
