def runPylintScan() {
    echo "🐍 Starting Pylint scan..."

    def buildNumber = env.BUILD_NUMBER
    def pythonServices = env.PYTHON_SERVICES

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

        // Run pylint and generate text + JSON report inside Docker
        sh """
            docker run --rm \
              -v "${sourceDir}:/code" \
              python:3.11 bash -c "
                pip install pylint pylint-json2sarif > /dev/null &&
                pylint /code > /code/pylint_report.txt ||
                echo '⚠️  Pylint failed for ${service}'
              "
        """

        // Copy text report
        sh "cp ${sourceDir}/pylint_report.txt ${txtReport} || true"

        // Generate JSON report (pylint’s JSON output needs rerun)
        sh """
            docker run --rm \
              -v "${sourceDir}:/code" \
              python:3.11 bash -c "
                pip install pylint > /dev/null &&
                pylint /code --output-format=json > /code/pylint_report.json || true
              "
        """
        sh "cp ${sourceDir}/pylint_report.json ${jsonReport} || true"

        // Generate SARIF report from JSON
        sh """
            docker run --rm \
              -v "${sourceDir}:/code" \
              python:3.11 bash -c "
                pip install pylint pylint-json2sarif > /dev/null &&
                pylint /code --output-format=json > /code/temp.json &&
                pylint-json2sarif -i /code/temp.json -o /code/pylint_report.sarif || true
              "
        """
        sh "cp ${sourceDir}/pylint_report.sarif ${sarifReport} || true"

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
