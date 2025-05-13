def createDockerBuild() {
    def buildNumber = env.BUILD_NUMBER
    def action = env.ACTION?.toLowerCase()
    def dockerServices = env.DOCKER_SERVICES?.split(',')?.collect { it.trim() }?.findAll { it }

    if (!buildNumber) {
        error "❌ Jenkins build number is not available!"
    }

    if (!dockerServices || dockerServices.isEmpty()) {
        error "❌ No valid DOCKER_SERVICES found in the environment!"
    }

    if (!action || !(action in ['create', 'destroy'])) {
        error "❌ Invalid or missing ACTION parameter. Must be 'create' or 'destroy'."
    }

    if (action == 'create') {
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

    } else if (action == 'destroy') {
        echo "🗑️ Removing Docker images for build number: ${buildNumber}"

        dockerServices.each { service ->
            def imageTag = "${service}:${buildNumber}"
            echo "🧹 Removing image: ${imageTag}"

            sh label: "Remove ${service}", script: """#!/bin/bash
                set -euo pipefail

                IMAGE_TAG="${service}:${buildNumber}"

                if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${service}:${buildNumber}\$"; then
                    docker rmi -f "${service}:${buildNumber}" || echo "⚠️ Failed to remove ${service}:${buildNumber}"
                    echo "✅ Removed ${service}:${buildNumber}"
                else
                    echo "ℹ️ Image ${service}:${buildNumber} not found. Skipping."
                fi
            """
        }

        echo "🧼 Docker image cleanup complete."
    }
}

return this
