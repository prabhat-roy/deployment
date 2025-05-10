def installSonarqube() {
    withCredentials([
        usernamePassword(credentialsId: 'jenkins-cred', usernameVariable: 'JENKINS_USER', passwordVariable: 'JENKINS_PASS')
    ]) {
        // Ensure the shell script is executable
        sh "chmod +x shell_script/sonarqube.sh"

        // Run the shell script with env vars passed through
        sh """
            export JENKINS_URL="${env.JENKINS_URL}"
            export JENKINS_USER="${JENKINS_USER}"
            export JENKINS_PASS="${JENKINS_PASS}"
            shell_script/sonarqube.sh
        """
    }
}

return this