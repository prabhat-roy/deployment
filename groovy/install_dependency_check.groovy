def installDependencyCheck() {
    def nvdDir = "/var/lib/jenkins/dependency-check-data"
    def owaspImage = "owasp/dependency-check:latest"

    echo "Starting OWASP Dependency-Check installation..."

    // Create the directory to persist NVD data
    sh "mkdir -p ${nvdDir}"

    // Pull the official OWASP Dependency-Check Docker image
    sh "docker pull ${owaspImage}"

    // Run the container to fetch NVD database
    sh """
        docker run --rm \
            -v ${nvdDir}:/usr/share/dependency-check/data \
            ${owaspImage} \
            --updateonly
    """

    echo "Dependency-Check setup complete. NVD data cached at ${nvdDir}"
}

def cleanupDependencyCheck() {
    def nvdDir = "/var/lib/jenkins/dependency-check-data"

    echo "Cleaning up OWASP Dependency-Check..."

    // Remove the cached NVD data directory
    sh "rm -rf ${nvdDir}"

    echo "Cleanup complete."
}

// Return functions so the script can be used like a class
return this
