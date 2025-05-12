def createDockerBuild() {
    def buildNumber = env.BUILD_NUMBER
    if (!buildNumber) {
        error "❌ Jenkins build number is not available!"
    }

    def dockerServices = env.DOCKER_SERVICES?.split(',')
    if (!dockerServices) {
        error "❌ No DOCKER_SERVICES found in the environment!"
    }

    echo "🐳 Starting Docker image build for build number: ${buildNumber}"

    dockerServices.each { service ->
        echo "📦 Building Docker image for service: ${service}"

        sh label: "Build ${service}", script: """#!/bin/bash
            set -euo pipefail

            SERVICE="${service}"
            BUILD_NUMBER="${buildNumber}"
            SERVICE_DIR="src/\${SERVICE}"

            echo "🔍 Checking directory: \${SERVICE_DIR}"
            if [[ ! -d "\${SERVICE_DIR}" ]]; then
              echo "⚠️  Skipping: Directory '\${SERVICE_DIR}' not found."
              exit 0
            fi

            IMAGE_TAG="\${SERVICE}:\${BUILD_NUMBER}"
            echo "📦 Building Docker image: \${IMAGE_TAG}"
            docker build --no-cache -t "\${IMAGE_TAG}" "\${SERVICE_DIR}"
            echo "✅ Built \${IMAGE_TAG}"
        """
    }

    echo "🚀 All Docker builds complete."
}

return this
