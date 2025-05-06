def call(String projectTokenId) {
    echo "🔍 Running Codacy scan..."

    withCredentials([string(credentialsId: projectTokenId, variable: 'CODACY_PROJECT_TOKEN')]) {
        sh """
            docker run --rm -t \
                -v \$(pwd):/src \
                -w /src \
                -e CODACY_PROJECT_TOKEN=\$CODACY_PROJECT_TOKEN \
                ${env.CODACY_IMAGE} \
                analyze \
                --format ${env.CODACY_OUTPUT_FORMAT} \
                --output ${env.CODACY_REPORT}
        """
    }
}
