def call() {
    def steps = this
    def toolName = 'OWASP-DependencyCheck'

    steps.node {
        steps.stage('OWASP Dependency-Check Scan') {
            def toolHome = steps.tool toolName

            def dcCmd = "${toolHome}/bin/dependency-check.sh"
            def reportDir = "${steps.env.WORKSPACE}/dependency-check-report"
            def scanDir = steps.env.WORKSPACE

            steps.echo "Using OWASP Dependency-Check tool at: ${toolHome}"

            steps.sh "mkdir -p '${reportDir}'"

            // Run dependency-check CLI with all formats
            def cmd = "${dcCmd} --scan '${scanDir}' --out '${reportDir}' " +
                      "--format HTML --format XML --format JSON --format CSV --format JUNIT"

            steps.echo "Running Dependency-Check CLI: ${cmd}"
            def rc = steps.sh(returnStatus: true, script: cmd)

            if (rc != 0) {
                steps.error("Dependency-Check scan failed with exit code ${rc}")
            }

            // Define all generated report files
            def artifacts = [
                'dependency-check-report/dependency-check-report.html',
                'dependency-check-report/dependency-check-report.xml',
                'dependency-check-report/dependency-check-report.json',
                'dependency-check-report/dependency-check-report.csv',
                'dependency-check-report/dependency-check-report.xml' // JUnit XML has the same name as XML report
            ]

            // Archive all artifacts if they exist
            artifacts.each { artifact ->
                if (steps.fileExists(artifact)) {
                    steps.archiveArtifacts artifacts: artifact, allowEmptyArchive: false
                    steps.echo "Archived artifact: ${artifact}"
                } else {
                    steps.echo "Artifact not found, skipping archive: ${artifact}"
                }
            }

            // Check XML report for vulnerabilities to mark build unstable
            def xmlReport = "${reportDir}/dependency-check-report.xml"
            if (steps.fileExists(xmlReport)) {
                def xmlContent = steps.readFile(xmlReport)
                if (xmlContent.contains("<vulnerability>")) {
                    steps.echo "Vulnerabilities detected in Dependency-Check report."
                    steps.currentBuild.result = 'UNSTABLE'
                } else {
                    steps.echo "No vulnerabilities detected."
                }
            } else {
                steps.echo "Warning: XML report not found to analyze vulnerabilities."
            }
        }
    }
}

return this
