// groovy/GolangCILintScan.groovy

def runGolangCILintScan = {
    try {
        echo "[INFO] Starting GolangCI-Lint scan..."

        // Running GolangCI-Lint scan inside a Docker container
        docker.image('golangci/golangci-lint:v1.49.0').inside {
            // Run the GolangCI-Lint scan
            sh 'golangci-lint run --out-format=checkstyle > golangci-lint-report.xml || true'
        }

        // Archiving the GolangCI-Lint report to Jenkins
        archiveArtifacts allowEmptyArchive: true, artifacts: 'golangci-lint-report.xml', followSymlinks: false

        // Post-scan actions
        echo "[INFO] GolangCI-Lint scan completed successfully and report archived."

    } catch (Exception e) {
        echo "[ERROR] GolangCI-Lint scan failed: ${e.message}"
        throw e  // Rethrow to fail the pipeline if GolangCI-Lint scan is critical
    }
}

return [runGolangCILintScan: runGolangCILintScan]