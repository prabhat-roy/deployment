class OpenJDKInstaller implements Serializable {
    def steps

    OpenJDKInstaller(steps) {
        this.steps = steps
    }

    void installOpenJDK21() {
        steps.sh "chmod +x shell_script/install_openjdk21_jenkins.sh"
        steps.sh "shell_script/install_openjdk21_jenkins.sh"
    }
}

return new OpenJDKInstaller(this)
