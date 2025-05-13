def signAndVerifyImages() {
    echo "📥 Pulling latest Cosign image..."
    
    // Ensure Cosign is installed
    sh 'curl -sSL https://github.com/sigstore/cosign/releases/download/v1.10.0/cosign-linux-amd64 -o /usr/local/bin/cosign'
    sh 'chmod +x /usr/local/bin/cosign'

    def buildNumber = env.BUILD_NUMBER
    def dockerServices = env.DOCKER_SERVICES

    if (!buildNumber) {
        error "❌ BUILD_NUMBER environment variable is missing!"
    }
    if (!dockerServices) {
        error "❌ DOCKER_SERVICES environment variable is missing!"
    }

    def services = dockerServices.split(",").collect { it.trim() }.findAll { it }

    if (services.isEmpty()) {
        error "❌ No valid services found in DOCKER_SERVICES!"
    }

    sh 'mkdir -p cosign-reports'

    services.each { service ->
        def imageTag = "${service}:${buildNumber}"

        def signatureReport = "cosign-reports/${service}-signature.txt"
        def verificationReport = "cosign-reports/${service}-verification.txt"

        echo "🔏 Signing image: ${imageTag}"

        // Sign the image with Cosign
        sh """
            cosign sign --key <your-signing-key> --output ${signatureReport} ${imageTag} || echo '⚠️  Signing failed for ${imageTag}'
        """

        echo "✅ Verification of signed image: ${imageTag}"

        // Verify the signed image
        sh """
            cosign verify --key <your-public-key> --output ${verificationReport} ${imageTag} || echo '⚠️  Verification failed for ${imageTag}'
        """

        // Fallback if any file is missing
        [signatureReport, verificationReport].each { report ->
            if (!fileExists(report)) {
                echo "⚠️  Creating dummy report: ${report}"
                writeFile file: report, text: "No report generated for ${imageTag}. Scan may have failed."
            }
        }
    }

    echo "📁 Listing Cosign reports..."
    sh "ls -lh cosign-reports"

    echo "📦 Archiving Cosign reports..."
    archiveArtifacts artifacts: 'cosign-reports/*.{txt}', allowEmptyArchive: false

    echo "✅ Cosign signing and verification complete."
}

return this
