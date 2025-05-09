def InstallPlugin() {
    withCredentials([usernamePassword(credentialsId: 'jenkins-cred', usernameVariable: 'JENKINS_USER', passwordVariable: 'JENKINS_PASS')]) {
        def pluginFile = 'Jenkinsfile/jenkins_plugin.txt'
        def cliJar = '/tmp/jenkins-cli.jar'

        // Download Jenkins CLI
        sh """
            if [ ! -f "${cliJar}" ]; then
                wget -q "${JENKINS_URL}/jnlpJars/jenkins-cli.jar" -O "${cliJar}"
            fi
        """

        def plugins = readFile(pluginFile)
            .split('\n')
            .collect { it.replaceAll('#.*', '').trim() }
            .findAll { it }

        echo "\n📦 Installing plugins from: ${pluginFile}"

        plugins.each { plugin ->
            def checkCmd = "java -jar ${cliJar} -s ${JENKINS_URL} -auth ${JENKINS_USER}:${JENKINS_PASS} list-plugins | grep -E '^${plugin} '"
            def isInstalled = sh(script: checkCmd, returnStatus: true) == 0

            if (isInstalled) {
                echo "${plugin.padRight(30)} | Already Installed"
            } else {
                echo "⬇️ Installing ${plugin}..."
                def installCmd = "java -jar ${cliJar} -s ${JENKINS_URL} -auth ${JENKINS_USER}:${JENKINS_PASS} install-plugin ${plugin} -deploy"
                def result = sh(script: installCmd, returnStatus: true)
                if (result == 0) {
                    echo "${plugin.padRight(30)} | ✅ Installed"
                } else {
                    echo "${plugin.padRight(30)} | ❌ Failed"
                }
            }
        }

        // Optional restart
        echo "🔄 Restarting Jenkins..."
        sh "java -jar ${cliJar} -s ${JENKINS_URL} -auth ${JENKINS_USER}:${JENKINS_PASS} safe-restart"
    }
}

return this
