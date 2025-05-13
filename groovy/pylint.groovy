def runPylintScan() {
    echo "🐍 Starting Pylint scan..."

    def buildNumber = env.BUILD_NUMBER
    def pythonServices = env.DOCKER_SERVICES

    if (!buildNumber) {
        error "❌ BUILD_NUMBER environment variable is missing!"
    }
    if (!pythonServices) {
        error "❌ PYTHON_SERVICES environment variable is missing!"
    }

    def services = pythonServices.split(",").collect { it.trim() }.findAll { it }

    if (services.isEmpty()) {
        error "❌ No valid Python services found in PYTHON_SERVICES!"
    }

    def workspace = pwd()
    def reportsDir = "${workspace}/pylint-reports"
    sh "mkdir -p ${reportsDir}"

    services.each { service ->
        def sourceDir = "${workspace}/src/${service}"
        def reportBase = "${reportsDir}/${service}"
        def txtReport = "${reportBase}.txt"
        def jsonReport = "${reportBase}.json"
        def sarifReport = "${reportBase}.sarif"

        echo "🔍 Running pylint for: ${sourceDir}"

        // Run pylint and generate text report inside Docker
        sh """
            docker run --rm \
              -v "${sourceDir}:/code" \
              python:3.11 bash -c "
                pip install pylint > /dev/null &&
                pylint /code > /code/pylint_report.txt ||
                echo '⚠️  Pylint failed for ${service}'
              "
        """

        // Check and copy the text report if it exists
        if (fileExists("${sourceDir}/pylint_report.txt")) {
            sh "cp ${sourceDir}/pylint_report.txt ${txtReport}"
        } else {
            echo "⚠️  Pylint text report not generated for ${service}."
        }

        // Generate JSON report
        sh """
            docker run --rm \
              -v "${sourceDir}:/code" \
              python:3.11 bash -c "
                pip install pylint > /dev/null &&
                pylint /code --output-format=json > /code/pylint_report.json || true
              "
        """

        // Check and copy the JSON report if it exists
        if (fileExists("${sourceDir}/pylint_report.json")) {
            sh "cp ${sourceDir}/pylint_report.json ${jsonReport}"
        } else {
            echo "⚠️  Pylint JSON report not generated for ${service}."
        }

        // Convert JSON to SARIF using sarif-tools (alternative to pylint-json2sarif)
        sh """
            docker run --rm \
              -v "${sourceDir}:/code" \
              python:3.11 bash -c "
                pip install pylint sarif-tools > /dev/null &&
                pylint /code --output-format=json > /code/pylint_report.json &&
                json2sarif -i /code/pylint_report.json -o /code/pylint_report.sarif || true
              "
        """

        // Check and copy the SARIF report if it exists
        if (fileExists("${sourceDir}/pylint_report.sarif")) {
            sh "cp ${sourceDir}/pylint_report.sarif ${sarifReport}"
        } else {
            echo "⚠️  Pylint SARIF report not generated for ${service}."
        }

        // Fallback dummy reports
        [txtReport, jsonReport, sarifReport].each { report ->
            if (!fileExists(report)) {
                echo "⚠️  Creating dummy report: ${report}"
                writeFile file: report, text: "No report generated for ${service}. Pylint may have failed."
            }
        }
    }

    echo "📁 Listing Pylint reports..."
    sh "ls -lh ${reportsDir}"

    echo "📦 Archiving Pylint reports..."
    archiveArtifacts artifacts: 'pylint-reports/*.{txt,json,sarif}', allowEmptyArchive: false

    echo "🧹 Cleaning up Pylint containers and image..."
    sh """
        docker ps -a -q --filter ancestor=python:3.11 | xargs -r docker rm -f || true
        docker rmi python:3.11 || true
    """

    echo "✅ Pylint scan and cleanup complete."
}

return this
