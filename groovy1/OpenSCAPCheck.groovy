// groovy/OpenSCAPCheck.groovy

def runOpenSCAPAudit = {
    try {
        echo "[INFO] Starting OpenSCAP Security Audit..."

        // Ensure OpenSCAP is installed in the environment
        sh 'yum install -y openscap-scanner'

        // Run OpenSCAP security audit (you can adjust the profile as per your need, e.g., DISA STIG or CIS)
        sh 'oscap oval eval --results scap-results.xml --report scap-report.html /usr/share/openscap/scap-yml/openscap-basic-profile.xml'

        // Archive the OpenSCAP results for later review
        archiveArtifacts allowEmptyArchive: true, artifacts: '**/scap-report.html', followSymlinks: false

        // If needed, you can also archive the XML result file
        archiveArtifacts allowEmptyArchive: true, artifacts: '**/scap-results.xml', followSymlinks: false

        echo "[INFO] OpenSCAP Security Audit completed and report archived."

    } catch (Exception e) {
        echo "[ERROR] OpenSCAP Security Audit failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if OpenSCAP check is critical
    }
}

return [runOpenSCAPAudit: runOpenSCAPAudit]