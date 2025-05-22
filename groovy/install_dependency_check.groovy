import jenkins.model.*
import hudson.tools.*
import hudson.util.Secret
import groovy.xml.XmlUtil
import groovy.xml.XmlParser

def JENKINS_URL = System.getenv('JENKINS_URL') ?: 'http://localhost:8080'
def CRED_ID = System.getenv('JENKINS_CREDS_ID') ?: 'jenkins-cred'

def nvdDir = "/var/lib/jenkins/dependency-check-data"
def owaspImage = "owasp/dependency-check:latest"

def installDependencyCheck() {
    echo "Starting OWASP Dependency-Check setup..."

    // 1. Create NVD data directory if not exists
    sh "mkdir -p ${nvdDir}"

    // 2. Pull OWASP Dependency-Check Docker image
    sh "docker pull ${owaspImage}"

    // 3. Run container to update local NVD database
    sh """
        docker run --rm \\
            -v ${nvdDir}:/usr/share/dependency-check/data \\
            ${owaspImage} \\
            --updateonly --verbose
    """

    echo "NVD data cached locally at: ${nvdDir}"

    // 4. Configure Jenkins to add Dependency-Check installation pointing to local NVD data
    configureDependencyCheckTool()
}

def configureDependencyCheckTool() {
    echo "Configuring Jenkins Dependency-Check tool..."

    // Get Jenkins instance
    def jenkins = Jenkins.instance

    // Read credentials for Jenkins HTTP auth (username/password)
    def creds = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
        com.cloudbees.plugins.credentials.common.StandardUsernamePasswordCredentials.class,
        jenkins,
        null,
        null
    ).find { it.id == CRED_ID }

    if (creds == null) {
        error "Credentials with ID '${CRED_ID}' not found!"
    }

    def user = creds.username
    def pass = creds.password.getPlainText()

    echo "Using credentials ID: ${CRED_ID} with user: ${user}"

    // Read current DependencyCheck tool configuration XML
    def desc = jenkins.getDescriptorByType(hudson.tools.ToolDescriptor.class)
    def depCheckDesc = jenkins.getDescriptorByType(org.jenkinsci.plugins.DependencyCheck.DependencyCheckInstallation.DescriptorImpl.class)

    if (depCheckDesc == null) {
        error "DependencyCheck plugin descriptor not found!"
    }

    // Prepare new installation XML config
    def xml = depCheckDesc.getConfigFile().asString()

    def parser = new XmlParser(false, false)
    def root = parser.parseText(xml)

    // Check if installation with this name exists
    def installationsNode = root.installations ? root.installations[0] : root.appendNode('installations')

    def existing = installationsNode.'org.jenkinsci.plugins.DependencyCheck.DependencyCheckInstallation'.find { it.name.text() == 'LocalNVD' }

    if (existing) {
        echo "Updating existing Dependency-Check installation 'LocalNVD'..."
        existing.home[0].value = nvdDir
        existing.nvdUrl[0].value = ''
    } else {
        echo "Adding new Dependency-Check installation 'LocalNVD'..."
        def installNode = installationsNode.appendNode('org.jenkinsci.plugins.DependencyCheck.DependencyCheckInstallation')
        installNode.appendNode('name', 'LocalNVD')
        installNode.appendNode('home', nvdDir)
        installNode.appendNode('nvdUrl', '') // empty disables external download to force local
    }

    // Save updated config XML
    def writer = new StringWriter()
    XmlUtil.serialize(root, writer)
    def newXml = writer.toString()

    // Write back updated config
    def configFile = depCheckDesc.getConfigFile()
    configFile.write(newXml)

    // Reload the config to apply changes immediately
    depCheckDesc.load()

    echo "Dependency-Check tool configured to use local NVD at: ${nvdDir}"
}

def cleanupDependencyCheck() {
    echo "Cleaning up OWASP Dependency-Check data..."

    sh "rm -rf ${nvdDir}"

    echo "Cleanup complete."
}

return this
