class JenkinsPluginInstaller implements Serializable {
    def steps

    JenkinsPluginInstaller(steps) {
        this.steps = steps
    }

    def installPlugins(String pluginFile = 'Jenkins/jenkins_plugin.txt') {
        steps.withCredentials([
            steps.usernamePassword(
                credentialsId: 'jenkins-cred',
                usernameVariable: 'JENKINS_USER',
                passwordVariable: 'JENKINS_PASS'
            )
        ]) {
            def cliJar = '/tmp/jenkins-cli.jar'

            steps.sh """
                if [ ! -f "${cliJar}" ]; then
                    wget -q "\$JENKINS_URL/jnlpJars/jenkins-cli.jar" -O "${cliJar}"
                fi
            """

            def plugins = steps.readFile(pluginFile)
                .split('\n')
                .collect { it.replaceAll('#.*', '').trim() }
                .findAll { it }

            steps.echo "\n📦 Installing plugins from: ${pluginFile}"

            boolean pluginInstalled = false

            plugins.each { plugin ->
                def isInstalled = steps.sh(
                    script: """
                        java -jar ${cliJar} -s \$JENKINS_URL -auth \$JENKINS_USER:\$JENKINS_PASS list-plugins | grep -E '^${plugin} '
                    """,
                    returnStatus: true
                ) == 0

                if (isInstalled) {
                    steps.echo "${plugin.padRight(30)} | Already Installed"
                } else {
                    steps.echo "⬇️ Installing ${plugin}..."
                    def result = steps.sh(
                        script: """
                            java -jar ${cliJar} -s \$JENKINS_URL -auth \$JENKINS_USER:\$JENKINS_PASS install-plugin ${plugin} -deploy
                        """,
                        returnStatus: true
                    )
                    if (result == 0) {
                        steps.echo "${plugin.padRight(30)} | ✅ Installed"
                        pluginInstalled = true
                    } else {
                        steps.echo "${plugin.padRight(30)} | ❌ Failed"
                    }
                }
            }
        }
    }
}
