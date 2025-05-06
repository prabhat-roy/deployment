// groovy/tools/checkov/archive_checkov_report.groovy
def archiveCheckovReport = {
    echo "📦 Archiving Checkov report..."
    archiveArtifacts artifacts: "${env.REPORT_FILE}", allowEmptyArchive: false
}

return [archiveCheckovReport: archiveCheckovReport]
