def createDockerBuild() {
    def buildNumber = env.BUILD_NUMBER
    if (!buildNumber) {
        error "❌ Jenkins build number is not available!"
    }

    def services = env.SERVICES?.split(',')
    if (!services) {
        error "❌ No SERVICES found in the environment!"
    }

    echo "🐳 Starting Docker image build for build number: ${buildNumber}"

    services.each { service ->
        echo "📦 Building Docker image for service: ${service}"

        sh label: "Build ${service}", script: """#!/bin/bash
            set -euo pipefail

            SERVICE="${service}"
            BUILD_NUMBER="${buildNumber}"

            echo "🐳 Building Docker image for service: \$SERVICE with tag: \$BUILD_NUMBER"

            SERVICE_DIR="src/\$SERVICE"
            if [[ ! -d "\$SERVICE_DIR" ]]; then
              echo "⚠️  Skipping: Directory '\$SERVICE_DIR' not found."
              exit 1
            fi

            IMAGE_TAG="\${SERVICE}:\${BUILD_NUMBER}"
            docker build --no-cache -t "\$IMAGE_TAG" "\$SERVICE_DIR"

            echo "✅ Built Docker image: \$IMAGE_TAG"
        """
    }

    echo "🚀 All Docker builds complete."
}

return this
