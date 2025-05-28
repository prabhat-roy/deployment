import hudson.model.*
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.CredentialsScope
import hudson.plugins.sonar.*

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
        steps.echo "🔧 Starting SonarQube installation..."

        steps.sh 'docker pull sonarqube:latest'

        steps.sh '''
            docker rm -f sonarqube || true
            docker run -d --name sonarqube -p 9000:9000 sonarqube:latest
        '''

        steps.echo "⏳ Waiting for SonarQube to be ready..."

        // Retry checking SonarQube readiness up to 10 times with 30s sleep intervals
        steps.retry(10) {
            steps.sleep 60
            def code = steps.sh(script: "curl -s -o /dev/null -w '%{http_code}' http://localhost:9000", returnStdout: true).trim()
            if (code != '200') {
                error "SonarQube not ready yet (HTTP status: ${code})"
            }
        }

        // Change default admin password (admin/admin) to a new secure password
        def defaultUser = 'admin'
        def defaultPass = 'admin'
        def newPass = 'sonar'  // Change this to your desired password

        def changePassResponse = steps.sh(
            script: """curl -s -o /dev/null -w '%{http_code}' -u ${defaultUser}:${defaultPass} \\
                -X POST '${getSonarQubeUrl()}/api/users/change_password' \\
                -d 'login=${defaultUser}&previousPassword=${defaultPass}&password=${newPass}'""",
            returnStdout: true
        ).trim()

        if (changePassResponse == '204') {
            steps.echo "🔐 Default admin password changed successfully."
        } else if (changePassResponse == '400') {
            steps.echo "⚠️ Password change failed. It may have already been updated."
        } else {
            steps.echo "⚠️ Unexpected response when changing password: ${changePassResponse}"
        }

        // Use the new password for token generation
        def adminUser = defaultUser
        def adminPass = newPass
        def tokenName = "jenkins-sonar-token-${System.currentTimeMillis()}"

        def tokenJson = steps.sh(
            script: """curl -s -u ${adminUser}:${adminPass} -X POST "${getSonarQubeUrl()}/api/user_tokens/generate?name=${tokenName}" """,
            returnStdout: true
        ).trim()

        def token = parseToken(tokenJson)
        if (!token) {
            steps.error "❌ Failed to generate SonarQube token"
        }

        steps.echo "✅ Token generated successfully."

        createCredential("sonarqube-token", adminUser, token)
        configureSonarQubeServer("sonarqube-token")

        steps.echo "🎉 SonarQube installation and Jenkins integration completed."
    }

    void cleanupSonarqube() {
        steps.echo "🧹 Cleaning up SonarQube resources..."
        steps.sh 'docker rm -f sonarqube || true'

        removeCredential("sonarqube-token")
        removeSonarQubeServer()

        steps.echo "✅ Cleanup completed."
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
            steps.error "❌ Jenkins instance not found!"
        }

        def domain = Domain.global()
        def store = jenkins.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

        def existing = CredentialsProvider.lookupCredentials(
            com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl.class, jenkins, null, null
        ).find { it.id == id }

        def credential = new com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl(
            CredentialsScope.GLOBAL, id, "SonarQube token", username, secret
        )

        if (existing) {
            store.updateCredentials(domain, existing, credential)
            steps.echo "🔄 Updated Jenkins credential '${id}'."
        } else {
            store.addCredentials(domain, credential)
            steps.echo "✅ Created Jenkins credential '${id}'."
        }
    }

    private void removeCredential(String id) {
        def jenkins = Jenkins.getInstanceOrNull()
        if (jenkins == null) {
            steps.echo "❌ Jenkins instance not found!"
            return
        }

        def domain = Domain.global()
        def store = jenkins.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

        def existing = CredentialsProvider.lookupCredentials(
            com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl.class, jenkins, null, null
        ).find { it.id == id }

        if (existing) {
            store.removeCredentials(domain, existing)
            steps.echo "🗑️ Removed Jenkins credential '${id}'."
        } else {
            steps.echo "ℹ️ Credential '${id}' not found."
        }
    }

    private void configureSonarQubeServer(String credentialId) {
        def jenkins = Jenkins.getInstanceOrNull()
        if (jenkins == null) {
            steps.error "❌ Jenkins instance not found!"
        }

        def descriptor = jenkins.getDescriptorByType(hudson.plugins.sonar.SonarGlobalConfiguration.class)
        if (descriptor == null) {
            steps.error "❌ SonarQube plugin not found. Please install the SonarQube plugin."
        }

        def existing = descriptor.installations.find { it.name == "LocalSonarQube" }
        if (existing != null) {
            steps.echo "ℹ️ SonarQube server 'LocalSonarQube' already configured."
            return
        }

        def sonarInstallation = new hudson.plugins.sonar.SonarInstallation(
            "LocalSonarQube",                  // name
            getSonarQubeUrl(),                // serverUrl
            credentialId,                     // server authentication token ID
            "", "", "", []                    // optional fields: sonarLogin, sonarPassword, etc.
        )

        def newList = descriptor.installations + sonarInstallation
        descriptor.setInstallations(newList as hudson.plugins.sonar.SonarInstallation[])
        descriptor.save()

        steps.echo "✅ SonarQube server 'LocalSonarQube' configured in Jenkins."
    }

    private void removeSonarQubeServer() {
        def jenkins = Jenkins.getInstanceOrNull()
        if (jenkins == null) {
            steps.echo "❌ Jenkins instance not found!"
            return
        }

        def descriptor = jenkins.getDescriptorByType(hudson.plugins.sonar.SonarGlobalConfiguration.class)
        if (descriptor == null) {
            steps.echo "⚠️ SonarQube plugin not found. Skipping removal."
            return
        }

        def newList = descriptor.installations.findAll { it.name != "LocalSonarQube" }
        if (newList.size() != descriptor.installations.size()) {
            descriptor.setInstallations(newList as hudson.plugins.sonar.SonarInstallation[])
            descriptor.save()
            steps.echo "🗑️ SonarQube server 'LocalSonarQube' removed from Jenkins."
        } else {
            steps.echo "ℹ️ SonarQube server 'LocalSonarQube' not found."
        }
    }
}

return new SonarqubeInstaller(steps, env, params)
