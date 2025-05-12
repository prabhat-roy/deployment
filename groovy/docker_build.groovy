def createDockerBuild() {
    // Get the build number from Jenkins
    def buildNumber = env.BUILD_NUMBER
    if (!buildNumber) {
        error "❌ Jenkins build number is not available!"
    }

    // Get the services list from the environment variable (comma-separated)
    def services = env.SERVICES?.split(',')
    if (!services) {
        error "❌ No SERVICES found in the environment!"
    }

    echo "🐳 Starting Docker image build for build number: ${buildNumber}"

    // Iterate over each service and call the shell script to build the Docker image
    services.each { service ->
        echo "📦 Building Docker image for service: ${service}"
        sh """
            chmod +x shell_script/docker_build.sh
            shell_script/docker_build.sh ${service} ${buildNumber}
        """
    }
}

return this
