class PythonInstaller implements Serializable {
    def steps

    PythonInstaller(steps) {
        this.steps = steps
    }

    void installPython() {
        steps.sh "chmod +x shell_script/install_python.sh"
        steps.sh "shell_script/install_python.sh"
    }
}

return new PythonInstaller(this)
