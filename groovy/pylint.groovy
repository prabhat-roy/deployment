def runPylintScan() {
    def containerName = "pylint_scan_container"
    def pylintImage = "python:3.11-slim"  // Official pylint image can be pulled directly or use a slim python image to install pylint
    
    try {
        // Pull the pylint image from the official Docker repository
        sh "docker pull ${pylintImage}"

        // Run pylint scan inside a container
        sh """
            docker run --name ${containerName} -v \$PWD:/workspace -w /workspace ${pylintImage} /bin/bash -c '
                pip install pylint > /dev/null 2>&1
                pylint . > pylint_report.txt || true
                pylint --output-format=json . > pylint_report.json || true
                pylint --output-format=html . > pylint_report.html || true
            '
        """

        // Archive the generated pylint reports (txt, json, html)
        archiveArtifacts artifacts: 'pylint_report.*', allowEmptyArchive: true
    } catch (err) {
        error "Pylint scan failed: ${err}"
    } finally {
        // Cleanup: Remove the pylint container
        sh "docker rm -f ${containerName} || true"

        // Remove the pylint image after scanning
        sh "docker rmi -f ${pylintImage} || true"
    }
}
return this
