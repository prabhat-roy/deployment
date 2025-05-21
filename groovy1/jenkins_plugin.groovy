def InstallPlugin() {
    withCredentials([usernamePassword(credentialsId: 'jenkins-cred', usernameVariable: 'JENKINS_USER', passwordVariable: 'JENKINS_PASS')]) {
        def pluginFile = 'Jenkins/jenkins_plugin.txt'
        def cliJar = '/tmp/jenkins-cli.jar'

        sh '''
            if [ ! -f "/tmp/jenkins-cli.jar" ]; then
                wget -q "$JENKINS_URL/jnlpJars/jenkins-cli.jar" -O "/tmp/jenkins-cli.jar"
            fi
        '''

        def plugins = readFile(pluginFile)
            .split('\n')
            .collect { it.replaceAll('#.*', '').trim() }
            .findAll { it }

        echo "\n📦 Installing plugins from: ${pluginFile}"

        boolean pluginInstalled = false

        plugins.each { plugin ->
            def isInstalled = sh(
                script: """
                    java -jar ${cliJar} -s \$JENKINS_URL -auth \$JENKINS_USER:\$JENKINS_PASS list-plugins | grep -E '^${plugin} '
                """,
                returnStatus: true
            ) == 0

            if (isInstalled) {
                echo "${plugin.padRight(30)} | Already Installed"
            } else {
                echo "⬇️ Installing ${plugin}..."
                def result = sh(
                    script: """
                        java -jar ${cliJar} -s \$JENKINS_URL -auth \$JENKINS_USER:\$JENKINS_PASS install-plugin ${plugin} -deploy
                    """,
                    returnStatus: true
                )
                if (result == 0) {
                    echo "${plugin.padRight(30)} | ✅ Installed"
                    pluginInstalled = true
                } else {
                    echo "${plugin.padRight(30)} | ❌ Failed"
                }
            }
        }
    }
}
return this
