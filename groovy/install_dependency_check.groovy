def nvdDir = "/opt/dependency-check-data"
def owaspImage = "owasp/dependency-check:latest"
def toolName = "OWASP-DependencyCheck"

def installDependencyCheck() {
    echo "🔧 Installing OWASP Dependency-Check..."

    createDirectory()
    pullDockerImage()
    updateNVD()
    registerTool()

    echo "✅ Dependency-Check setup complete."
}

def cleanupDependencyCheck() {
    echo "🧹 Cleaning up Dependency-Check..."

    removeDirectory()
    deregisterTool()

    echo "✅ Cleanup complete."
}

private def runShell(String cmd) {
    def proc = ['bash', '-c', cmd].execute()
    proc.in.eachLine { println "[shell] $it" }
    proc.err.eachLine { println "[error] $it" }
    proc.waitFor()
    if (proc.exitValue() != 0) {
        throw new RuntimeException("Shell command failed: $cmd")
    }
}

private def createDirectory() {
    echo "📁 Creating directory: ${nvdDir}"
    runShell("sudo mkdir -p ${nvdDir}")
    runShell("sudo chown -R \$(whoami) ${nvdDir}")
}

private def removeDirectory() {
    echo "🗑️ Removing directory: ${nvdDir}"
    runShell("sudo rm -rf ${nvdDir}")
}

private def pullDockerImage() {
    echo "🐳 Pulling Docker image: ${owaspImage}"
    runShell("docker pull ${owaspImage}")
}

private def updateNVD() {
    echo "🌐 Downloading NVD data..."
    def dockerCmd = """
        docker run --rm \\
            -v ${nvdDir}:/usr/share/dependency-check/data \\
            ${owaspImage} \\
            --updateonly --verbose
    """.stripIndent().trim()
    runShell(dockerCmd)
}

@NonCPS
private def registerTool() {
    echo "🔧 Registering '${toolName}' in Jenkins tools..."

    def jenkins = jenkins.model.Jenkins.getInstance()
    def descriptor = jenkins.getDescriptorByType(org.jenkinsci.plugins.DependencyCheck.DependencyCheckInstallation.DescriptorImpl)
    def installations = descriptor.getInstallations().toList()

    def existing = installations.find { it.name == toolName }

    if (existing) {
        println "✔ Tool '${toolName}' already exists. Updating home to ${nvdDir}"
        existing.home = nvdDir
    } else {
        println "➕ Registering new tool '${toolName}' at ${nvdDir}"
        def newTool = new org.jenkinsci.plugins.DependencyCheck.DependencyCheckInstallation(toolName, nvdDir, null)
        installations.add(newTool)
    }

    descriptor.setInstallations(installations.toArray(new org.jenkinsci.plugins.DependencyCheck.DependencyCheckInstallation[0]))
    descriptor.save()
    jenkins.save()
}

@NonCPS
private def deregisterTool() {
    echo "🗑️ Removing '${toolName}' from Jenkins tools..."

    def jenkins = jenkins.model.Jenkins.getInstance()
    def descriptor = jenkins.getDescriptorByType(org.jenkinsci.plugins.DependencyCheck.DependencyCheckInstallation.DescriptorImpl)
    def installations = descriptor.getInstallations().findAll { it.name != toolName }

    descriptor.setInstallations(installations.toArray(new org.jenkinsci.plugins.DependencyCheck.DependencyCheckInstallation[0]))
    descriptor.save()
    jenkins.save()
}

return this
