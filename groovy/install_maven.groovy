class MavenInstaller implements Serializable {

    def steps

    MavenInstaller(steps) {
        this.steps = steps
    }

    def installMaven() {
        steps.sh "chmod +x shell_script/install_maven.sh"
        steps.sh "shell_script/install_maven.sh"
    }
}

return new MavenInstaller(this)