def runPylintScan() {
    def pylintImage = "python:3.11-slim"  // Official python image to run pylint inside the container
    def services = "${env.DOCKER_SERVICES}".split(",") // Get services list from DOCKER_SERVICES environment variable

    // Pull the pylint image once
    sh "docker pull ${pylintImage}"

    // Create a container that will be reused for all services
    def containerName = "pylint_scan_container"
    sh """
        docker run --name ${containerName} -d -v /var/lib/jenkins/workspace:/workspace -w /workspace ${pylintImage} sleep 3600
    """
    
    services.each { service ->
        try {
            // Run pylint scan for each service inside the container
            sh """
                docker exec ${containerName} /bin/bash -c '
                    cd /workspace/src/${service}
                    pip install pylint pylint-json2html > /dev/null 2>&1
                    pylint **/*.py > pylint_report_${service}.txt || true
                    pylint --output-format=json **/*.py > pylint_report_${service}.json || true
                    pylint-json2html -o pylint_report_${service}.html pylint_report_${service}.json || true
                '
            """

            // Archive the generated pylint reports (txt, json, html)
            archiveArtifacts artifacts: "src/${service}/pylint_report_${service}.*", allowEmptyArchive: true
        } catch (err) {
            error "Pylint scan failed for service ${service}: ${err}"
        }
    }

    // Cleanup: Remove the pylint container and the image after scanning
    sh "docker rm -f ${containerName} || true"
    sh "docker rmi -f ${pylintImage} || true"
}
return this
