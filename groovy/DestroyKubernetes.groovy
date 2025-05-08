def destroyKubernetesResources = {
    echo "[INFO] Starting Kubernetes cleanup process..."

    def helmRelease = "my-app"
    def namespace = "default" // Change if using a custom namespace

    // Step 1: Delete LoadBalancer service first
    echo "[INFO] Deleting LoadBalancer service (my-app-service)..."
    sh "kubectl delete svc my-app-service -n ${namespace} --ignore-not-found"

    // Step 2: Wait until LoadBalancer IP/DNS is released
    def maxRetries = 20
    def retryInterval = 10
    def lbStillExists = true

    for (int i = 0; i < maxRetries; i++) {
        def result = sh(
            script: "kubectl get svc my-app-service -n ${namespace} -o jsonpath='{.status.loadBalancer.ingress[0]}' 2>/dev/null || echo ''",
            returnStdout: true
        ).trim()

        if (!result) {
            lbStillExists = false
            echo "[INFO] LoadBalancer resources cleaned up successfully."
            break
        }
        echo "[INFO] Waiting for LoadBalancer to be fully released... (${i + 1}/${maxRetries})"
        sleep(retryInterval)
    }

    if (lbStillExists) {
        echo "[WARN] LoadBalancer cleanup timed out after ${maxRetries * retryInterval} seconds."
    }

    // Step 3: Check and uninstall Helm release
    def helmExists = sh(
        script: "helm ls -n ${namespace} | grep -w ${helmRelease} || true",
        returnStdout: true
    ).trim()

    if (helmExists) {
        echo "[INFO] Uninstalling Helm release: ${helmRelease} from namespace: ${namespace}"
        sh "helm uninstall ${helmRelease} -n ${namespace}"
    } else {
        echo "[WARN] Helm release '${helmRelease}' not found. Falling back to manual YAML cleanup..."

        // Step 4: Fallback manual deletion of Kubernetes resources
        try {
            sh '''
                kubectl delete -f k8s/deployment.yaml --ignore-not-found
                kubectl delete -f k8s/configmap.yaml --ignore-not-found
                kubectl delete -f k8s/pvc.yaml --ignore-not-found
                kubectl delete -f k8s/secret.yaml --ignore-not-found
                kubectl delete -f k8s/ingress.yaml --ignore-not-found
            '''
        } catch (Exception e) {
            error "[ERROR] Failed to delete manual Kubernetes resources: ${e.message}"
        }
    }

    // Step 5: Confirm resource cleanup
    echo "[INFO] Verifying cleanup..."

    // Check for any remaining resources
    def remainingPods = sh(
        script: "kubectl get pods -n ${namespace} --no-headers | wc -l",
        returnStdout: true
    ).trim()

    if (remainingPods != "0") {
        echo "[WARN] Some pods may still be terminating. Total remaining: ${remainingPods}"
    }

    // Check for any remaining services, deployments, configmaps, etc.
    def remainingResources = sh(
        script: "kubectl get all -n ${namespace} --no-headers | wc -l",
        returnStdout: true
    ).trim()

    if (remainingResources != "0") {
        echo "[WARN] Some resources may still be present. Total remaining: ${remainingResources}"
    }

    echo "[INFO] Kubernetes cleanup completed."
}

return [destroyKubernetesResources: destroyKubernetesResources]
