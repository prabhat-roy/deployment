def deployToKubernetes = { Map args ->
    // Required parameters
    def releaseName     = args.releaseName     ?: error("[ERROR] Missing required parameter: releaseName")
    def chartPath       = args.chartPath       ?: error("[ERROR] Missing required parameter: chartPath")
    def namespace       = args.namespace       ?: "default"
    def valuesFile      = args.valuesFile      ?: ""
    def additionalArgs  = args.additionalArgs  ?: ""
    def kubeContext     = args.kubeContext     ?: "" // optional

    echo "[INFO] Deploying '${releaseName}' to namespace '${namespace}' using Helm chart '${chartPath}'..."

    try {
        // Create namespace if it doesn't exist
        sh "kubectl get ns ${namespace} || kubectl create ns ${namespace}"

        // Helm dependencies (if any)
        if (fileExists("${chartPath}/Chart.yaml")) {
            echo "[INFO] Checking for Helm dependencies..."
            sh "helm dependency update ${chartPath}"
        }

        // Build Helm install/upgrade command
        def helmCmd = "helm upgrade --install ${releaseName} ${chartPath} --namespace ${namespace} --wait --timeout 5m"
        if (valuesFile) {
            helmCmd += " -f ${valuesFile}"
        }
        if (additionalArgs) {
            helmCmd += " ${additionalArgs}"
        }
        if (kubeContext) {
            helmCmd += " --kube-context ${kubeContext}"
        }

        echo "[INFO] Running Helm command: ${helmCmd}"
        sh "${helmCmd}"

        echo "[INFO] Deployment '${releaseName}' completed successfully."
    } catch (Exception e) {
        error "[ERROR] Deployment failed: ${e.message}"
    }
}

return [deployToKubernetes: deployToKubernetes]
