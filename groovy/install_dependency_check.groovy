// Note: This groovy file is loaded inside Jenkins pipeline script

def nvdDir = "/var/lib/jenkins/dependency-check-data"
def owaspImage = "owasp/dependency-check:latest"
def jenkinsUrl = env.JENKINS_URL ?: "http://localhost:8080"
def credentialsId = "jenkins-cred" // Your Jenkins credential ID

def installDependencyCheck() {
    echo "Starting OWASP Dependency-Check installation..."

    // Create directory (must be writable by Jenkins user)
    sh "mkdir -p ${nvdDir}"

    // Pull the official OWASP Dependency-Check Docker image
    sh "docker pull ${owaspImage}"

    // Run container to download NVD data, show verbose progress
    sh """
        docker run --rm \\
            -v ${nvdDir}:/usr/share/dependency-check/data \\
            ${owaspImage} \\
            --updateonly --verbose
    """

    echo "NVD data cached at ${nvdDir}"

    // Configure Jenkins Dependency-Check installation to use local NVD data
    configureJenkinsDependencyCheck()
}

def cleanupDependencyCheck() {
    echo "Cleaning up OWASP Dependency-Check data..."
    sh "rm -rf ${nvdDir}"
    echo "Cleanup complete."
}

// Configure Dependency-Check tool in Jenkins with local NVD path
def configureJenkinsDependencyCheck() {
    echo "Configuring Jenkins Dependency-Check tool installation..."

    // Must run this part on Jenkins master JVM thread and outside sandbox
    // So mark this function as @NonCPS (No pipeline CPS transformation)

    configureToolInJenkins()
}

@NonCPS
def configureToolInJenkins() {
    def jenkins = Jenkins.getInstance()
    def desc = jenkins.getDescriptorByType(org.jenkinsci.plugins.DependencyCheck.DependencyCheckInstallation.DescriptorImpl.class)

    def installations = desc.getInstallations() as List

    def found = false
    for (inst in installations) {
        if (inst.name == 'LocalNVD') {
            inst.home = nvdDir
            found = true
        }
    }

    if (!found) {
        def newInst = new org.jenkinsci.plugins.DependencyCheck.DependencyCheckInstallation('LocalNVD', nvdDir, null)
        installations.add(newInst)
    }

    desc.setInstallations(installations.toArray(new org.jenkinsci.plugins.DependencyCheck.DependencyCheckInstallation[0]))
    desc.save()

    echo "Configured Dependency-Check tool with local NVD data path: ${nvdDir}"
}

// Return this so pipeline can call functions
return this
