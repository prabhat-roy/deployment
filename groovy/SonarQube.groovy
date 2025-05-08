def runSonarQubeScan = { String sonarProjectKey, String sonarHostUrl ->
    echo "[INFO] Running SonarQube scan on the entire project..."

    withCredentials([string(credentialsId: 'sonarqube-token-id', variable: 'SONAR_TOKEN')]) {
        sh """
            sonar-scanner \
                -Dsonar.projectKey=${sonarProjectKey} \
                -Dsonar.sources=. \
                -Dsonar.login=\$SONAR_TOKEN \
                -Dsonar.host.url=${sonarHostUrl}
        """

        echo "[INFO] SonarQube scan completed. Waiting for Quality Gate..."
        waitForQualityGate(sonarProjectKey, sonarHostUrl)
    }

    echo "[INFO] Quality Gate passed, proceeding to next step."
}

def waitForQualityGate = { String sonarProjectKey, String sonarHostUrl ->
    withCredentials([string(credentialsId: 'sonarqube-token-id', variable: 'SONAR_TOKEN')]) {
        timeout(time: 10, unit: 'MINUTES') {
            waitUntil {
                script {
                    def response = sh(
                        script: """curl -s -u \$SONAR_TOKEN: '${sonarHostUrl}/api/qualitygates/project_status?projectKey=${sonarProjectKey}'""",
                        returnStdout: true
                    ).trim()

                    def status = readJSON(text: response).projectStatus.status
                    echo "[INFO] SonarQube Quality Gate status: ${status}"
                    return status == 'OK'
                }
            }
        }
    }
}

def archiveSonarQubeReport = {
    echo "[INFO] Archiving SonarQube report (if present)..."
    archiveArtifacts artifacts: '**/target/sonar-report.html', fingerprint: true
}

return [
    runSonarQubeScan: runSonarQubeScan,
    waitForQualityGate: waitForQualityGate,
    archiveSonarQubeReport: archiveSonarQubeReport
]
