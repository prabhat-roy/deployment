def InstallPlugin() {
    withCredentials([usernamePassword(credentialsId: 'jenkins-cred', usernameVariable: 'JENKINS_USER', passwordVariable: 'JENKINS_PASS')]) {
        sh """
            chmod +x shell_script/jenkins_plugin.sh
            JENKINS_URL="${env.JENKINS_URL}" JENKINS_USER="${JENKINS_USER}" JENKINS_PASS="${JENKINS_PASS}" \
            ./shell_script/jenkins_plugin.sh
        """
    }
}

return this
