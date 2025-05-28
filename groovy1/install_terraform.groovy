class TerraformInstaller implements Serializable {
    def steps

    TerraformInstaller(steps) {
        this.steps = steps
    }

    void installTerraform() {
        steps.sh "chmod +x shell_script/install_terraform.sh"
        steps.sh "shell_script/install_terraform.sh"
    }
}

return new TerraformInstaller(this)
