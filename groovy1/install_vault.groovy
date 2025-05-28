class VaultCLIInstaller implements Serializable {
    def steps

    VaultCLIInstaller(steps) {
        this.steps = steps
    }

    void installVaultCLI() {
        steps.sh "chmod +x shell_script/install_vault_cli.sh"
        steps.sh "shell_script/install_vault_cli.sh"
    }
}

return new VaultCLIInstaller(this)
