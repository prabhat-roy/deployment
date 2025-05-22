import groovy.json.JsonSlurper

class ToolConfiguration {

    def steps
    def env

    ToolConfiguration(steps, env) {
        this.steps = steps
        this.env = env
    }

    def toolConfiguration() {
        // Load Jenkins credentials
        def jenkinsUrl = env.JENKINS_URL
        def credsId = env.JENKINS_CREDS_ID

        steps.echo "Starting tool configuration via Jenkins REST API"

        // Fetch Jenkins credentials from withCredentials block
        steps.withCredentials([steps.usernamePassword(credentialsId: credsId, usernameVariable: 'JENKINS_USER', passwordVariable: 'JENKINS_TOKEN')]) {
            def user = steps.env.JENKINS_USER
            def token = steps.env.JENKINS_TOKEN

            // For demo, print user (do NOT print token in real use)
            steps.echo "Using Jenkins user: ${user}"

            // Define the tools you want to configure
            def tools = [
                maven: getMavenToolInfo(),
                ant: getAntToolInfo(),
                gradle: getGradleToolInfo(),
                nodejs: getNodejsToolInfo(),
                docker: getDockerToolInfo(),
                jdk: getJdkToolInfo()
            ]

            // You will fetch current config.xml from Jenkins, modify the tool section, and POST it back
            def configXmlFile = 'config.xml'
            def updatedConfigXmlFile = 'config_updated.xml'

            // Download current Jenkins config.xml
            def downloadCmd = """
                curl -s -u ${user}:${token} ${jenkinsUrl}/config.xml -o ${configXmlFile}
            """
            steps.sh(downloadCmd)

            // Parse the config.xml file using Groovy XML parser
            def configXml = new XmlParser().parse(configXmlFile)

            // Modify or add tools to configXml
            configureToolsInXml(configXml, tools)

            // Write updated XML back to file
            def writer = new StringWriter()
            new XmlNodePrinter(new PrintWriter(writer)).print(configXml)
            steps.writeFile file: updatedConfigXmlFile, text: writer.toString()

            // POST updated config.xml back to Jenkins to apply tool config changes
            def postCmd = """
                curl -s -X POST -u ${user}:${token} \\
                -H "Content-Type: application/xml" \\
                --data-binary @${updatedConfigXmlFile} \\
                ${jenkinsUrl}/config.xml
            """
            steps.sh(postCmd)

            steps.echo "Tools configured successfully."
        }
    }

    private Map getMavenToolInfo() {
        def version = getInstalledVersion('mvn', ['-v'])
        def location = getCommandLocation('mvn')
        return [name: "Maven_${version}", home: location]
    }

    private Map getAntToolInfo() {
        def version = getInstalledVersion('ant', ['-version'])
        def location = getCommandLocation('ant')
        return [name: "Ant_${version}", home: location]
    }

    private Map getGradleToolInfo() {
        def version = getInstalledVersion('gradle', ['-v'])
        def location = getCommandLocation('gradle')
        return [name: "Gradle_${version}", home: location]
    }

    private Map getNodejsToolInfo() {
        def version = getInstalledVersion('node', ['-v'])
        def location = getCommandLocation('node')
        return [name: "NodeJS_${version}", home: location]
    }

    private Map getDockerToolInfo() {
        def version = getInstalledVersion('docker', ['--version'])
        def location = getCommandLocation('docker')
        return [name: "Docker_${version}", home: location]
    }

    private Map getJdkToolInfo() {
        // Assuming java binary is on PATH
        def version = getInstalledVersion('java', ['-version'])
        def location = getCommandLocation('java')
        // For JDK, home is usually two levels up from java binary, adjust accordingly
        def home = steps.sh(script: "dirname \$(dirname \$(readlink -f \$(which java)))", returnStdout: true).trim()
        return [name: "JDK_${version}", home: home]
    }

    private String getInstalledVersion(String cmd, List args) {
        try {
            def out = steps.sh(script: "${cmd} ${args.join(' ')}", returnStdout: true).trim()
            // Extract first line/version info for common commands
            def firstLine = out.readLines()[0]
            return firstLine.replaceAll('[^0-9\\.]+', '') // only version digits & dots
        } catch (Exception e) {
            steps.echo "Failed to get version for ${cmd}: ${e.message}"
            return "unknown"
        }
    }

    private String getCommandLocation(String cmd) {
        try {
            def location = steps.sh(script: "which ${cmd}", returnStdout: true).trim()
            return location
        } catch (Exception e) {
            steps.echo "Failed to get location for ${cmd}: ${e.message}"
            return ""
        }
    }

    private void configureToolsInXml(def configXml, Map tools) {
        // Tools are under <tool> elements inside <toolLocations> or <toolInstallations> depending on Jenkins version
        // This is a simplified example updating <toolLocations> section
        
        def toolLocationsNode = configXml.'toolLocations'[0]
        if (!toolLocationsNode) {
            toolLocationsNode = new Node(configXml, 'toolLocations')
        }

        // Clear existing toolLocations
        toolLocationsNode.replaceNode {
            toolLocationsNode = 'toolLocations'()
        }

        // For each tool, add a <toolLocation> entry
        tools.each { key, value ->
            if (value.home) {
                def toolNode = new Node(toolLocationsNode, 'toolLocation')
                new Node(toolNode, 'name', value.name)
                new Node(toolNode, 'home', value.home)
            }
        }
    }
}

return new ToolConfiguration(this, env)
