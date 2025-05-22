class GradleInstaller implements Serializable {
    def steps

    GradleInstaller(steps) {
        this.steps = steps
    }

    void installGradle() {
        steps.withCredentials([steps.usernamePassword(credentialsId: "${steps.env.JENKINS_CREDS_ID}", usernameVariable: 'JENKINS_USER', passwordVariable: 'JENKINS_PASS')]) {
            steps.sh """
                chmod +x shell_script/install_gradle.sh
                shell_script/install_gradle.sh \\
                    --jenkins-url="${steps.env.JENKINS_URL}" \\
                    --username="\$JENKINS_USER" \\
                    --password="\$JENKINS_PASS"
            """
        }
    }
}

return new GradleInstaller(this)
