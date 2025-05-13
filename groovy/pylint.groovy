def runPylintScan() {
    def containerName = "pylint_scan_container"
    def imageName = env.DOCKER_SERVICES ?: "python:3.11-slim"  // Fallback to default if env.DOCKER_SERVICES is not set

    try {
        // Pull the Docker image for scanning
        sh "docker pull ${imageName}"

        // Run pylint inside a temporary container
        sh """
            docker run --name ${containerName} -v \$PWD:/workspace -w /workspace ${imageName} /bin/bash -c '
                pip install pylint > /dev/null 2>&1
                pylint . > pylint_report.txt || true
                pylint --output-format=json . > pylint_report.json || true
                pylint --output-format=html . > pylint_report.html || true
            '
        """

        // Archive all generated report formats
        archiveArtifacts artifacts: 'pylint_report.*', allowEmptyArchive: true
    } catch (err) {
        error "Pylint scan failed: ${err}"
    } finally {
        // Cleanup container
        sh "docker rm -f ${containerName} || true"

        // Remove the Docker image after scanning
        sh "docker rmi -f ${imageName} || true"
    }
}
return this
