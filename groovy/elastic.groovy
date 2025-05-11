def deployElasticStack() {
    echo "[INFO] Deploying Elastic Stack via Helm..."
    sh 'bash scripts/deploy-elastic-stack.sh'
}
return this
