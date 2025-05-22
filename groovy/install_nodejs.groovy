class NodejsInstaller implements Serializable {
    def steps

    NodejsInstaller(steps) {
        this.steps = steps
    }

    void installNodejs() {
        steps.sh 'chmod +x shell_script/install_nodejs.sh'
        steps.withCredentials([steps.usernamePassword(credentialsId: 'jenkins-cred', usernameVariable: 'JENKINS_USER', passwordVariable: 'JENKINS_PASS')]) {
            steps.sh """
                export JENKINS_URL=http://localhost:8080
                ./shell_script/install_nodejs.sh
            """
        }
    }
}

return new NodejsInstaller(this)
