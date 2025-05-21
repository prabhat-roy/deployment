def runFlake8AndArchiveReports() {
    echo "📥 Pulling latest Python image with Flake8..."
    sh 'docker pull python:3.11-slim'

    def reportFile = "flake8-report.txt"

    echo "🔍 Running Flake8 scan on current workspace..."
    sh """
        docker run --rm \
            -v \$(pwd):/code \
            -w /code \
            python:3.11-slim /bin/bash -c "
                pip install flake8 && \
                flake8 . > ${reportFile} || echo '⚠️  Flake8 scan completed with issues.'
            "
    """

    if (!fileExists(reportFile)) {
        echo "⚠️  Creating dummy report: ${reportFile}"
        writeFile file: reportFile, text: "No Flake8 report generated. Scan may have failed."
    }

    echo "📦 Archiving Flake8 report..."
    archiveArtifacts artifacts: "${reportFile}", allowEmptyArchive: false

    echo "✅ Flake8 scan and archive complete."
}

return this
