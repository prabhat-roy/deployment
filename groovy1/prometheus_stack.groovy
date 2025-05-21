def managePrometheus(String action) {
    def cloudProvider = env.CLOUD_PROVIDER?.toLowerCase()

    if (!cloudProvider) {
        error "CLOUD_PROVIDER environment variable is not set"
    }

    echo "Cloud Provider Detected: ${cloudProvider}"

    def chartPath = "prometheus-stack"
    def valuesFile = "${chartPath}/values.yaml"
    def grafanaTlsDir = "${chartPath}/templates/grafana/tls"
    def alertTlsDir = "${chartPath}/templates/alert-manager/tls"

    if (action == "create") {
        // 1. Generate TLS certificates
        [grafanaTlsDir, alertTlsDir].each { dir ->
            sh "mkdir -p ${dir}"
            sh """
                openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                  -keyout ${dir}/tls.key -out ${dir}/tls.crt \
                  -subj "/CN=monitoring/O=monitoring"
            """
        }

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

        // 4. Deploy Helm chart with SMTP and TLS settings
        sh """
            helm upgrade --install prometheus-stack ${chartPath} -n monitoring --create-namespace \\
              --set alertmanager.smtp.host="${env.SMTP_HOST}" \\
              --set alertmanager.smtp.port="${env.SMTP_PORT}" \\
              --set alertmanager.smtp.from="${env.SMTP_FROM}" \\
              --set alertmanager.smtp.to="${env.SMTP_TO}" \\
              --set alertmanager.smtp.username="${env.SMTP_USER}" \\
              --set alertmanager.smtp.password="${env.SMTP_PASS}" \\
              --set-file alertmanager.tls.cert=${alertTlsDir}/tls.crt \\
              --set-file alertmanager.tls.key=${alertTlsDir}/tls.key \\
              --set-file grafana.tls.cert=${grafanaTlsDir}/tls.crt \\
              --set-file grafana.tls.key=${grafanaTlsDir}/tls.key
        """

    } else if (action == "destroy") {
        // Delete the release and cleanup
        sh "helm uninstall prometheus-stack -n monitoring || true"
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
