def manageElasticStack(String action) {
    def chartPath = 'elastic-stack'
    def releaseName = 'elastic-stack'
    def namespace = 'elastic'
    def valuesFile = "${chartPath}/values.yaml"

    if (!(action in ['create', 'destroy'])) {
        error "❌ Invalid action '${action}'. Allowed: create, destroy"
    }

    if (action == 'create') {
        echo "📦 Installing Elastic Stack"
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
        echo "✅ Elastic Stack ${releaseExists ? 'upgraded' : 'installed'} successfully."

    } else if (action == 'destroy') {
        echo "🔥 Uninstalling Elastic Stack"

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
