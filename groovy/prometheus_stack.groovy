def managePrometheusStack(String action) {
    def chartPath = 'helm/monitoring-stack'
    def releaseName = 'monitoring-stack'
    def namespace = 'monitoring'
    def valuesFile = "${chartPath}/values.yaml"

    if (!(action in ['create', 'destroy'])) {
        error "❌ Invalid action '${action}'. Allowed: create, destroy"
    }

    if (action == 'create') {
        echo "📦 Installing Prometheus & Grafana Stack"
        sh """
            if ! kubectl get ns ${namespace} >/dev/null 2>&1; then
                echo "🔧 Creating namespace '${namespace}'..."
                kubectl create namespace ${namespace}
            fi
        """

        def releaseExists = sh(script: "helm list -n ${namespace} | grep -w ${releaseName} || true", returnStdout: true).trim()

        def cmd = releaseExists
            ? "helm upgrade ${releaseName} ${chartPath} -n ${namespace} --install"
            : "helm install ${releaseName} ${chartPath} -n ${namespace}"

        if (fileExists(valuesFile)) {
            cmd += " -f ${valuesFile}"
        }

        sh cmd
        echo "✅ Monitoring stack ${releaseExists ? 'upgraded' : 'installed'} successfully."

    } else if (action == 'destroy') {
        echo "🔥 Uninstalling Prometheus & Grafana Stack"

        def releaseExists = sh(script: "helm list -n ${namespace} | grep -w ${releaseName} || true", returnStdout: true).trim()

        if (releaseExists) {
            sh "helm uninstall ${releaseName} -n ${namespace}"
            echo "✅ Helm release '${releaseName}' removed."
        } else {
            echo "ℹ️ Release '${releaseName}' not found. Skipping."
        }
    }
}

return this
