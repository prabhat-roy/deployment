class GradleInstaller implements Serializable {
    def steps

    GradleInstaller(steps) {
        this.steps = steps
    }

    void installGradle() {
        steps.sh """
            chmod +x shell_script/install_gradle.sh
            shell_script/install_gradle.sh
        """
    }
}

return new GradleInstaller(this)
