def createPylintConfig(String serviceDir) {
    // Optional: Custom Pylint config (not needed if using find instead)
    writeFile(file: "${serviceDir}/.pylintrc", text: """
[MASTER]
ignore=__init__.py
    """)
}

def runPylintScan() {
    echo "🐍 Starting Pylint scan..."

    def buildNumber = env.BUILD_NUMBER
    def pythonServices = env.DOCKER_SERVICES

    if (!buildNumber) {
        error "❌ BUILD_NUMBER environment variable is missing!"
    }
    if (!pythonServices) {
        error "❌ DOCKER_SERVICES environment variable is missing!"
    }

    def services = pythonServices.split(",").collect { it.trim() }.findAll { it }
    if (services.isEmpty()) {
        error "❌ No valid Python services found in DOCKER_SERVICES!"
    }

    def workspace = pwd()
    def reportsDir = "${workspace}/pylint-reports"
    sh "mkdir -p ${reportsDir}"

    services.each { service ->
        def serviceDir = "${workspace}/src/${service}"
        createPylintConfig(serviceDir)

        def reportBase = "${reportsDir}/${service}"
        def txtReport = "${reportBase}.txt"
        def jsonReport = "${reportBase}.json"
        def sarifReport = "${reportBase}.sarif"

        echo "🔍 Running pylint for: ${serviceDir}"

        // Docker Pylint with file filtering and fallback
        def pylintCmd = """
            docker run --rm \
              -v "${serviceDir}:/code" \
              python:3.11 bash -c '
                pip install pylint > /dev/null &&
                cd /code &&
                find . -type f -name "*.py" ! -name "__init__.py" > filelist.txt &&
                if [ -s filelist.txt ]; then
                  pylint \$(cat filelist.txt) > pylint_report.txt || true;
                  pylint \$(cat filelist.txt) --output-format=json > pylint_report.json || true;
                  pip install sarif-tools > /dev/null &&
                  json2sarif -i pylint_report.json -o pylint_report.sarif || true;
                else
                  echo "No Python files found." > pylint_report.txt;
                  echo "[]" > pylint_report.json;
                  echo "{}" > pylint_report.sarif;
                fi
              '
        """
        echo "Running Pylint command: ${pylintCmd}"
        sh pylintCmd

        // Copy reports if generated
        [['txt', txtReport], ['json', jsonReport], ['sarif', sarifReport]].each { ext, dest ->
            def src = "${serviceDir}/pylint_report.${ext}"
            if (fileExists(src)) {
                sh "cp ${src} ${dest}"
            } else {
                echo "⚠️  Pylint ${ext.toUpperCase()} report not generated for ${service}."
                writeFile file: dest, text: "No ${ext} report generated for ${service}."
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
