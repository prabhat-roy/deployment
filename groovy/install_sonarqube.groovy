// File: groovy/install_sonarqube.groovy

import hudson.model.*
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.CredentialsScope

class SonarqubeInstaller implements Serializable {
    def steps
    def env
    def params

    SonarqubeInstaller(steps, env, params) {
        this.steps = steps
        this.env = env
        this.params = params
    }

    void installSonarqube() {
        steps.echo "Starting SonarQube installation..."

        // Pull latest SonarQube image
        steps.sh 'docker pull sonarqube:latest'

        // Run SonarQube container detached on port 9000
        steps.sh '''
            docker rm -f sonarqube || true
            docker run -d --name sonarqube -p 9000:9000 sonarqube:latest
        '''

        // Wait for SonarQube to start (adjust if needed)
        steps.echo "Waiting 60 seconds for SonarQube to start..."
        steps.sleep 60

        def adminUser = 'admin'
        def adminPass = 'admin'
        def tokenName = "jenkins-sonar-token-${System.currentTimeMillis()}"

        // Generate token via API
        def tokenJson = steps.sh(
            script: """curl -s -u ${adminUser}:${adminPass} -X POST "${getSonarQubeUrl()}/api/user_tokens/generate?name=${tokenName}" """,
            returnStdout: true
        ).trim()

        def token = parseToken(tokenJson)

        if (!token) {
            steps.error "Failed to generate SonarQube token"
        }

        steps.echo "SonarQube token generated."

        createCredential("sonarqube-token", "admin", token)
        configureSonarQubeServer(token)

        steps.echo "SonarQube installation and Jenkins configuration completed."
    }

    void cleanupSonarqube() {
        steps.echo "Stopping and removing SonarQube container..."
        steps.sh '''
            docker rm -f sonarqube || true
        '''

        removeCredential("sonarqube-token")
        removeSonarQubeServer()

        steps.echo "SonarQube cleanup completed."
    }

    private String getSonarQubeUrl() {
        return "http://localhost:9000"
    }

    private String parseToken(String json) {
        def matcher = json =~ /"token"\s*:\s*"([^"]+)"/
        if (matcher.find()) {
            return matcher.group(1)
        }
        return null
    }

    private void createCredential(String id, String username, String secret) {
        def jenkins = Jenkins.getInstanceOrNull()
        if (jenkins == null) {
            steps.error "Jenkins instance not found!"
        }
        def domain = Domain.global()
        def store = jenkins.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

        def existing = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
            com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl.class,
            jenkins,
            null,
            null
        ).find { it.id == id }

        if (existing != null) {
            store.updateCredentials(domain, existing, new UsernamePasswordCredentialsImpl(
                CredentialsScope.GLOBAL, id, "SonarQube token", username, secret
            ))
            steps.echo "Credential '${id}' updated."
        } else {
            def cred = new UsernamePasswordCredentialsImpl(
                CredentialsScope.GLOBAL, id, "SonarQube token", username, secret
            )
            store.addCredentials(domain, cred)
            steps.echo "Credential '${id}' created."
        }
    }

    private void removeCredential(String id) {
        def jenkins = Jenkins.getInstanceOrNull()
        if (jenkins == null) {
            steps.echo "Jenkins instance not found!"
            return
        }
        def domain = Domain.global()
        def store = jenkins.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

        def existing = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
            com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl.class,
            jenkins,
            null,
            null
        ).find { it.id == id }

        if (existing != null) {
            store.removeCredentials(domain, existing)
            steps.echo "Credential '${id}' removed."
        } else {
            steps.echo "Credential '${id}' not found."
        }
    }

    private void configureSonarQubeServer(String token) {
        def jenkins = Jenkins.getInstanceOrNull()
        if (jenkins == null) {
            steps.error "Jenkins instance not found!"
        }

        def descriptor = jenkins.getDescriptor("hudson.plugins.sonar.SonarGlobalConfiguration")
        if (descriptor == null) {
            steps.echo "SonarQube plugin not installed."
            return
        }

        def servers = descriptor.getServers() ?: []

        if (servers.any { it.name == "LocalSonarQube" }) {
            steps.echo "SonarQube server 'LocalSonarQube' already configured."
            return
        }

        def server = new hudson.plugins.sonar.SonarInstallation(
            "LocalSonarQube",
            getSonarQubeUrl(),
            token,
            null,
            null,
            null
        )
        servers.add(server)
        descriptor.setServers(servers)
        descriptor.save()

        steps.echo "SonarQube server 'LocalSonarQube' configured."
    }

    private void removeSonarQubeServer() {
        def jenkins = Jenkins.getInstanceOrNull()
        if (jenkins == null) {
            steps.echo "Jenkins instance not found!"
            return
        }

        def descriptor = jenkins.getDescriptor("hudson.plugins.sonar.SonarGlobalConfiguration")
        if (descriptor == null) {
            steps.echo "SonarQube plugin not installed."
            return
        }

        def servers = descriptor.getServers() ?: []
        def newServers = servers.findAll { it.name != "LocalSonarQube" }

        if (servers.size() != newServers.size()) {
            descriptor.setServers(newServers)
            descriptor.save()
            steps.echo "SonarQube server 'LocalSonarQube' removed."
        } else {
            steps.echo "SonarQube server 'LocalSonarQube' not found."
        }
    }
}

return new SonarqubeInstaller(steps, env, params)
