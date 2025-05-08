// groovy/owaspScan.groovy

def runDependencyCheck = {
    echo "[INFO] Starting OWASP Dependency-Check scan..."

    // Run scan using the Dockerized Dependency-Check wrapper
    sh '''
        dependency-check --scan . --format "HTML" --out /opt/dependency-check/reports
    '''

    echo "[INFO] Scan completed. Archiving report..."

    // Archive the generated report in Jenkins
    archiveArtifacts artifacts: '/opt/dependency-check/reports/dependency-check-report.html', fingerprint: true

    echo "[SUCCESS] OWASP Dependency-Check report archived successfully."
}

return [runDependencyCheck: runDependencyCheck]
