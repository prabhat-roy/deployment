class GnupgInstaller implements Serializable {
    def steps

    GnupgInstaller(steps) {
        this.steps = steps
    }

    void installGnupg() {
        steps.sh "chmod +x shell_script/install_gnupg.sh"
        steps.sh "shell_script/install_gnupg.sh"
    }
}

return new GnupgInstaller(this)
