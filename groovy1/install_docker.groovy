class DockerInstaller implements Serializable {
    def steps

    DockerInstaller(steps) {
        this.steps = steps
    }

    void installDocker() {
        steps.echo "🐳 Installing Docker using shell script..."

        // Make sure the shell script is executable
        steps.sh "chmod +x shell_script/install_docker.sh"

        // Call the shell script to install Docker
        steps.sh "shell_script/install_docker.sh"
    }
}

return new DockerInstaller(this)