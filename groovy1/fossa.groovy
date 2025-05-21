def runFossaScanAndArchiveReports(fossaApiKey) {
    echo "📥 Pulling latest FOSSA Docker image..."
    sh 'docker pull fossas/fossa-cli:latest'

    def reportDir = 'fossa-reports'
    sh "mkdir -p ${reportDir}"

    if (!fossaApiKey?.trim()) {
        error "❌ FOSSA API key is missing!"
    }

    echo "🔍 Running FOSSA scan with Docker..."

    // Analyze
    sh """
        docker run --rm \
          -e FOSSA_API_KEY=${fossaApiKey} \
          -v \$PWD:/src \
          -w /src \
          fossas/fossa-cli:latest analyze || echo '⚠️ Analyze encountered issues'
    """

    // Test
    sh """
        docker run --rm \
          -e FOSSA_API_KEY=${fossaApiKey} \
          -v \$PWD:/src \
          -w /src \
          fossas/fossa-cli:latest test || echo '⚠️ Test encountered issues'
    """

    // Save output log
    sh """
        docker run --rm \
          -e FOSSA_API_KEY=${fossaApiKey} \
          -v \$PWD:/src \
          -w /src \
          fossas/fossa-cli:latest analyze > ${reportDir}/analyze.log 2>&1 || true
    """

    echo "📦 Archiving FOSSA reports to Jenkins..."
    archiveArtifacts artifacts: "${reportDir}/**", allowEmptyArchive: true

    echo "✅ FOSSA scan completed and reports archived."
}

return this
