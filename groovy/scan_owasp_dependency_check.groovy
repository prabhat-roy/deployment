def scanAndArchiveSource() {
    def dcDataDir = "/opt/owasp/data"
    def dcReportDir = "${env.WORKSPACE}/dependency-check-report"
    def dcProject = "source-scan-${env.BUILD_TAG}"
    def dcSource = "${env.WORKSPACE}"

    sh """
        mkdir -p ${dcDataDir}
        mkdir -p ${dcReportDir}
        docker run --rm \
            -v ${dcSource}:/src \
            -v ${dcDataDir}:/usr/share/dependency-check/data \
            -v ${dcReportDir}:/report \
            --user $(id -u):$(id -g) \
            owasp/dependency-check:latest \
            --scan /src \
            --format ALL \
            --project "${dcProject}" \
            --out /report \
            --disableAssembly
    """

    archiveArtifacts artifacts: 'dependency-check-report/*.*', fingerprint: true
    echo "Dependency-Check report generated and archived successfully."
}
