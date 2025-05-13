def scanAndArchiveReports() {
    echo "📥 Pulling latest Python image with Bandit..."
    sh 'docker pull pyupio/bandit:latest'

    def scanPath = env.BANDIT_SCAN_PATH ?: '.'
    def reportDir = 'bandit-reports'

    echo "📁 Creating Bandit report directory..."
    sh "mkdir -p ${reportDir}"

    def txtReport   = "${reportDir}/bandit_report.txt"
    def jsonReport  = "${reportDir}/bandit_report.json"
    def sarifReport = "${reportDir}/bandit_report.sarif"

    echo "🔍 Running Bandit scan in Docker on path: ${scanPath}"

    // Table
    sh """
        docker run --rm -v \$PWD:/src pyupio/bandit:latest \
          bandit -r /src/${scanPath} -f txt -o /src/${txtReport} || echo '⚠️ TXT scan failed'
    """

    // JSON
    sh """
        docker run --rm -v \$PWD:/src pyupio/bandit:latest \
          bandit -r /src/${scanPath} -f json -o /src/${jsonReport} || echo '⚠️ JSON scan failed'
    """

    // SARIF
    sh """
        docker run --rm -v \$PWD:/src pyupio/bandit:latest \
          bandit -r /src/${scanPath} -f sarif -o /src/${sarifReport} || echo '⚠️ SARIF scan failed'
    """

    [txtReport, jsonReport, sarifReport].each { report ->
        if (!fileExists(report)) {
            echo "⚠️ Creating fallback report: ${report}"
            writeFile file: report, text: "No report generated for scan path '${scanPath}'."
        }
    }

    echo "📦 Archiving Bandit reports..."
    archiveArtifacts artifacts: "${reportDir}/*.{txt,json,sarif}", allowEmptyArchive: false

    echo "✅ Bandit Docker scan complete and reports archived."
}

return this
