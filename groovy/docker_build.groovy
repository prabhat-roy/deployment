def createDockerBuild() {
    def servicesEnv = env.SERVICES
    def buildNumber = env.BUILD_NUMBER ?: 'latest'
    def srcDir = 'src'

    if (!servicesEnv) {
        error "❌ SERVICES environment variable is not set!"
    }

    def services = servicesEnv.split(',').collect { it.trim() }

    echo "🚀 Starting Docker build for services: ${services}"
    echo "🔖 Using build number as tag: ${buildNumber}"

    services.each { service ->
        def serviceDir = "${srcDir}/${service}"
        echo "🔍 Checking service directory: ${serviceDir}"

        // Find Dockerfile recursively in the service directory
        def dockerfilePath = findDockerfile(serviceDir)

        if (dockerfilePath == null) {
            echo "⚠️ No Dockerfile found for service '${service}', skipping build."
            return
        }

        echo "🐳 Building Docker image for service '${service}' using Dockerfile at: ${dockerfilePath}"

        // Build Docker image with tag service:BUILD_NUMBER
        sh """
            docker build -t ${service}:${buildNumber} -f ${dockerfilePath} ${serviceDir}
        """
        echo "✅ Docker image built: ${service}:${buildNumber}"
    }
}

// Helper method to recursively find Dockerfile in a directory
def findDockerfile(String dir) {
    def dockerfile = null
    dir = dir.endsWith('/') ? dir : dir + '/'

    // Use shell to find Dockerfile path, limit to 1 result
    try {
        dockerfile = sh(
            script: "find '${dir}' -type f -name Dockerfile | head -n 1",
            returnStdout: true
        ).trim()
        if (dockerfile == '') {
            dockerfile = null
        }
    } catch (err) {
        dockerfile = null
    }

    return dockerfile
}

return this
