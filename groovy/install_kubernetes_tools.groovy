class KubernetesInstaller implements Serializable {
    def steps

    KubernetesInstaller(steps) {
        this.steps = steps
    }

    void installKubernetes() {
        steps.sh "chmod +x shell_script/install_kubernetes_tools.sh"
        steps.sh "shell_script/install_kubernetes_tools.sh"
    }
}

return new KubernetesInstaller(this)
