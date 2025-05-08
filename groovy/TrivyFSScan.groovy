def runTrivyScanAndArchive = { String srcDir, String reportDir ->
    echo "[INFO] Running Trivy Source Scan on directory: ${srcDir}"

    // Ensure report directory exists
    sh "mkdir -p '${reportDir}'"

    // Run Trivy scan using the latest Docker image
    sh """
        docker pull aquasec/trivy:latest
        docker run --rm \
          -v "\${PWD}/${srcDir}:/src" \
          -v "\${PWD}/${reportDir}:/report" \
          aquasec/trivy:latest fs /src \
          --format table \
          --output /report/trivy-source.txt
    """

    echo "[✔] Trivy scan completed. Report generated at ${reportDir}/trivy-source.txt"

    // Archive the report
    archiveArtifacts artifacts: "${reportDir}/**", fingerprint: true
    echo "[✔] Trivy report archived successfully."
}

return [runTrivyScanAndArchive: runTrivyScanAndArchive]
