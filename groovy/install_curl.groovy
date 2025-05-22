class CurlInstaller implements Serializable {
    def steps

    CurlInstaller(steps) {
        this.steps = steps
    }

    void installCurl() {
        steps.sh "chmod +x shell_script/install_curl.sh"
        steps.sh "shell_script/install_curl.sh"
    }
}

return new CurlInstaller(this)
