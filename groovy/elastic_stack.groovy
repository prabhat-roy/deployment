def manageElastic(String action) {
    def cloudProvider = env.CLOUD_PROVIDER?.toLowerCase()

    if (!cloudProvider) {
        error "CLOUD_PROVIDER environment variable is not set"
    }

    echo "Cloud Provider Detected: ${cloudProvider}"

    def chartPath = "elastic-stack"
    def valuesFile = "${chartPath}/values.yaml"
    def kibanaTlsDir = "${chartPath}/templates/kibana/tls"

    if (action == "create") {
        // 1. Generate TLS cert for Kibana
        sh "mkdir -p ${kibanaTlsDir}"
        sh """
            openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
              -keyout ${kibanaTlsDir}/tls.key -out ${kibanaTlsDir}/tls.crt \
              -subj "/CN=kibana/O=elastic"
        """

        // 2. Create monitoring namespace if it doesn't exist
        sh """
            if ! kubectl get namespace monitoring > /dev/null 2>&1; then
                kubectl create namespace monitoring
            fi
        """

        // 3. Update storage class in values.yaml
        def storageClass = getStorageClassForCloud(cloudProvider)
        if (!storageClass) {
            error "Unsupported cloud provider: ${cloudProvider}"
        }

        echo "Using Storage Class: ${storageClass}"
        sh "sed -i 's/defaultStorageClass:.*/defaultStorageClass: ${storageClass}/' ${valuesFile}"

        // 4. Deploy Helm chart
        sh """
            helm upgrade --install elastic-stack ${chartPath} -n monitoring --create-namespace \\
              --set elasticsearch.enabled=true \\
              --set kibana.enabled=true \\
              --set-file kibana.tls.cert=${kibanaTlsDir}/tls.crt \\
              --set-file kibana.tls.key=${kibanaTlsDir}/tls.key \\
              --set fleetServer.enabled=true \\
              --set agent.enabled=true
        """

    } else if (action == "destroy") {
        // Delete the release and cleanup
        sh "helm uninstall elastic-stack -n monitoring || true"
        sh "kubectl delete namespace monitoring --ignore-not-found"
    } else {
        error "Unsupported ACTION: ${action}. Must be 'create' or 'destroy'."
    }
}

def getStorageClassForCloud(String cloud) {
    switch(cloud) {
        case "aws":
            return "gp2"
        case "azure":
            return "managed-premium"
        case "gcp":
            return "standard"
        default:
            return null
    }
}

return this
