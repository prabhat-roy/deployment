class MavenInstaller implements Serializable {
    def steps

    MavenInstaller(steps) {
        this.steps = steps
    }

    void installMaven() {
        steps.withCredentials([steps.usernamePassword(credentialsId: "${steps.env.JENKINS_CREDS_ID}", usernameVariable: 'JENKINS_USER', passwordVariable: 'JENKINS_PASS')]) {
            steps.sh """
                chmod +x shell_script/install_maven.sh
                shell_script/install_maven.sh \\
                    --jenkins-url="${steps.env.JENKINS_URL}" \\
                    --username="\$JENKINS_USER" \\
                    --password="\$JENKINS_PASS"
            """
        }
    }
}

return new MavenInstaller(this)
