class ChefInstaller implements Serializable {
    def steps

    ChefInstaller(steps) {
        this.steps = steps
    }

    void installChef() {
        steps.sh "chmod +x shell_script/install_chef.sh"
        steps.sh "shell_script/install_chef.sh"
    }
}

return new ChefInstaller(this)
