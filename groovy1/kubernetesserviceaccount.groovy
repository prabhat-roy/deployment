def createServiceAccount() {
    echo "[INFO] Creating Kubernetes ServiceAccount and ClusterRoleBinding..."
    sh 'bash scripts/kubernetes-sa.sh'
}
return this
