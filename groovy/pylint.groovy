def runPylintScan() {
    def containerNamePrefix = "pylint_scan_container_"
    def pylintImage = "python:3.11-slim"  // Official python image to run pylint inside the container
    def services = "${env.DOCKER_SERVICES}".split(",") // Get services list from DOCKER_SERVICES environment variable
    
    services.each { service ->
        def containerName = "${containerNamePrefix}${service}"

        try {
            // Pull the pylint image from the official Docker repository
            sh "docker pull ${pylintImage}"

            // Run pylint scan inside the container for each service in DOCKER_SERVICES
            sh """
                docker run --name ${containerName} -v /var/lib/jenkins/workspace/${service}:/workspace -w /workspace ${pylintImage} /bin/bash -c '
                    pip install pylint pylint-json2html > /dev/null 2>&1
                    pylint . > pylint_report_${service}.txt || true
                    pylint --output-format=json . > pylint_report_${service}.json || true
                    pylint-json2html -o pylint_report_${service}.html pylint_report_${service}.json || true
                '
            """

            // Archive the generated pylint reports (txt, json, html)
            archiveArtifacts artifacts: "pylint_report_${service}.*", allowEmptyArchive: true
        } catch (err) {
            error "Pylint scan failed for service ${service}: ${err}"
        } finally {
            // Cleanup: Remove the pylint container
            sh "docker rm -f ${containerName} || true"

            // Remove the pylint image after scanning
            sh "docker rmi -f ${pylintImage} || true"
        }
    }
}
return this
