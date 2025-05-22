class ToolConfiguration {
    def steps
    def env

    ToolConfiguration(steps, env) {
        this.steps = steps
        this.env = env
    }

    def toolConfiguration() {
        def tools = [:]

        // Detect JDK
        def jdkHome = steps.sh(script: "readlink -f \$(which java) | sed 's:/bin/java::'", returnStdout: true).trim()
        def jdkVersion = steps.sh(script: "java -version 2>&1 | head -n 1", returnStdout: true).trim()
        tools['jdk'] = [name: 'jdk', home: jdkHome, version: jdkVersion]

        // Detect Maven
        def mavenHome = steps.sh(script: "readlink -f \$(which mvn) | sed 's:/bin/mvn::'", returnStdout: true).trim()
        def mavenVersion = steps.sh(script: "mvn -version | head -n 1", returnStdout: true).trim()
        tools['maven'] = [name: 'maven', home: mavenHome, version: mavenVersion]

        // Detect Gradle
        def gradleHome = steps.sh(script: "readlink -f \$(which gradle) | sed 's:/bin/gradle::'", returnStdout: true).trim()
        def gradleVersion = steps.sh(script: "gradle -version | grep Gradle | head -n 1", returnStdout: true).trim()
        tools['gradle'] = [name: 'gradle', home: gradleHome, version: gradleVersion]

        // Detect Ant
        def antHome = steps.sh(script: "readlink -f \$(which ant) | sed 's:/bin/ant::'", returnStdout: true).trim()
        def antVersion = steps.sh(script: "ant -version 2>&1 | head -n 1", returnStdout: true).trim()
        tools['ant'] = [name: 'ant', home: antHome, version: antVersion]

        // Detect NodeJS
        def nodeHome = steps.sh(script: "dirname \$(readlink -f \$(which node))", returnStdout: true).trim()
        def nodeVersion = steps.sh(script: "node -v", returnStdout: true).trim()
        tools['nodejs'] = [name: 'nodejs', home: nodeHome, version: nodeVersion]

        // Detect Docker
        def dockerHome = steps.sh(script: "dirname \$(readlink -f \$(which docker))", returnStdout: true).trim()
        def dockerVersion = steps.sh(script: "docker --version", returnStdout: true).trim()
        tools['docker'] = [name: 'docker', home: dockerHome, version: dockerVersion]

        steps.echo "Detected tools: ${tools}"

        // Configure Jenkins tools
        def jenkinsInstance = jenkins.model.Jenkins.get()
        def globalToolConfig = jenkinsInstance.getDescriptorByType(jenkins.model.Jenkins.instance.getDescriptorByType(hudson.tools.ToolDescriptor).getClass())

        def jenkinsTools = jenkinsInstance.getDescriptorByType(jenkins.model.Jenkins.instance.getDescriptorByType(hudson.tools.ToolInstallation).getClass())
        def existingTools = jenkinsInstance.getDescriptorByType(hudson.tools.ToolInstallation.DescriptorImpl.class)?.installations ?: []

        // Clear and add detected tools
        def newTools = []
        tools.each { key, value ->
            def toolClass
            switch(key) {
                case 'jdk':
                    toolClass = hudson.tools.JDK
                    break
                case 'maven':
                    toolClass = hudson.tasks.Maven$MavenInstallation
                    break
                case 'gradle':
                    toolClass = org.jenkinsci.plugins.gradle.GradleInstallation
                    break
                case 'ant':
                    toolClass = hudson.tasks.Ant$AntInstallation
                    break
                case 'nodejs':
                    toolClass = jenkins.plugins.nodejs.tools.NodeJSInstallation
                    break
                case 'docker':
                    toolClass = com.nirima.jenkins.plugins.docker.DockerTool
                    break
                default:
                    toolClass = null
            }
            if(toolClass != null){
                def tool = toolClass.newInstance(value.name, value.home, [])
                newTools << tool
            }
        }

        // Update Jenkins global tools configuration (example for JDK only)
        def jdkDescriptor = jenkinsInstance.getDescriptorByType(hudson.model.JDK.DescriptorImpl)
        jdkDescriptor.setInstallations(newTools.findAll{ it instanceof hudson.tools.JDK } as hudson.tools.ToolInstallation[])
        jdkDescriptor.save()

        // Similarly, update other tools descriptors as needed...

        steps.echo "Jenkins tools configured successfully"
    }
}

return new ToolConfiguration(steps, env)
