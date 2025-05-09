def InstallPlugin() {
    withCredentials([usernamePassword(credentialsId: 'jenkins-cred', usernameVariable: 'JENKINS_USER', passwordVariable: 'JENKINS_PASS')]) {
        sh """
            chmod +x shell_script/jenkins_plugin.sh
            export JENKINS_URL="${JENKINS_URL}"
            export JENKINS_USER="${JENKINS_USER}"
            export JENKINS_PASS="${JENKINS_PASS}"
            ./shell_script/jenkins_plugin.sh
        """
    }
}

return this
