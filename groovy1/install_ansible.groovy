class AnsibleInstaller implements Serializable {
    def steps

    AnsibleInstaller(steps) {
        this.steps = steps
    }

    void installAnsible() {
        steps.sh "chmod +x shell_script/install_ansible.sh"
        steps.sh "shell_script/install_ansible.sh"
    }
}

return new AnsibleInstaller(this)
