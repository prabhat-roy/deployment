// groovy/updateKubeconfig.groovy

def updateKubeconfig = {
    // Detect the cloud environment (AWS, Azure, GCP)
    def cloudEnv = sh(script: 'curl -s http://169.254.169.254/latest/meta-data/', returnStdout: true).trim()

    // Assuming cloudEnv will have specific endpoints or metadata that are unique to each cloud environment
    if (cloudEnv.contains('aws')) {
        echo "[INFO] Detected AWS environment. Updating kubeconfig for EKS."

        // AWS - Update kubeconfig for EKS
        def eksClusterName = "your-eks-cluster-name"
        def region = "us-east-1" // Set your AWS region
        sh "aws eks --region ${region} update-kubeconfig --name ${eksClusterName}"

    } else if (cloudEnv.contains('azure')) {
        echo "[INFO] Detected Azure environment. Updating kubeconfig for AKS."

        // Azure - Update kubeconfig for AKS
        def aksClusterName = "your-aks-cluster-name"
        def aksResourceGroup = "your-aks-resource-group"
        def aksRegion = "eastus" // Set your Azure region
        sh "az aks get-credentials --resource-group ${aksResourceGroup} --name ${aksClusterName} --region ${aksRegion}"

    } else if (cloudEnv.contains('googleapis')) {
        echo "[INFO] Detected GCP environment. Updating kubeconfig for GKE."

        // GCP - Update kubeconfig for GKE
        def gkeClusterName = "your-gke-cluster-name"
        def gkeProjectId = "your-gcp-project-id"
        def gkeRegion = "us-central1" // Set your GCP region
        sh "gcloud container clusters get-credentials ${gkeClusterName} --project ${gkeProjectId} --region ${gkeRegion}"

    } else {
        error "[ERROR] Unknown cloud environment. Cannot update kubeconfig."
    }

    echo "[INFO] Kubeconfig updated successfully for Kubernetes deployment."
}

return [updateKubeconfig: updateKubeconfig]
