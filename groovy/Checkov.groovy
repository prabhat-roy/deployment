// groovy/checkovScan.groovy

def runCheckovScan = {
    echo "[INFO] Fetching the latest Checkov Docker image..."

    // Pull the latest Checkov Docker image
    sh '''
        docker pull bridgecrew/checkov:latest
    '''

    echo "[INFO] Starting Checkov scan..."

    // Run Checkov scan using the Docker image
    sh '''
        docker run --rm \
        -v \$PWD:/workspace \
        bridgecrew/checkov:latest --directory /workspace --output json --output-file /workspace/checkov-report.json
    '''

    echo "[INFO] Checkov scan completed. Archiving report..."

    // Archive the generated Checkov report in Jenkins
    archiveArtifacts artifacts: 'checkov-report.json', fingerprint: true

    echo "[SUCCESS] Checkov scan completed and report archived successfully."
}

return [runCheckovScan: runCheckovScan]
