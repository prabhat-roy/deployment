import groovy.util.XmlParser
import groovy.util.Node

def runShell(steps, cmd) {
    try {
        return steps.sh(script: cmd, returnStdout: true).trim()
    } catch (err) {
        return null
    }
}

def detectTools(steps) {
    def tools = [:]

    // JDK
    def javaHome = runShell(steps, "dirname \$(dirname \$(readlink -f \$(which java)))")
    def javaVersion = runShell(steps, "java -version 2>&1 | head -n 1")
    if (javaHome) {
        tools['jdk'] = [name: 'JDK', home: javaHome, version: javaVersion]
    }

    // Maven
    def mvnHome = runShell(steps, "dirname \$(dirname \$(readlink -f \$(which mvn)))")
    def mvnVersion = runShell(steps, "mvn -version | head -n 1")
    if (mvnHome) {
        tools['maven'] = [name: 'Maven', home: mvnHome, version: mvnVersion]
    }

    // Gradle
    def gradleHome = runShell(steps, "dirname \$(dirname \$(readlink -f \$(which gradle)))")
    def gradleVersion = runShell(steps, "gradle -version | grep 'Gradle '")
    if (gradleHome) {
        tools['gradle'] = [name: 'Gradle', home: gradleHome, version: gradleVersion]
    }

    // Ant
    def antHome = runShell(steps, "dirname \$(dirname \$(readlink -f \$(which ant)))")
    def antVersion = runShell(steps, "ant -version")
    if (antHome) {
        tools['ant'] = [name: 'Ant', home: antHome, version: antVersion]
    }

    // NodeJS
    def nodeHome = runShell(steps, "dirname \$(dirname \$(readlink -f \$(which node)))")
    def nodeVersion = runShell(steps, "node --version")
    if (nodeHome) {
        tools['nodejs'] = [name: 'NodeJS', home: nodeHome, version: nodeVersion]
    }

    // Docker
    def dockerHome = runShell(steps, "dirname \$(dirname \$(readlink -f \$(which docker)))")
    def dockerVersion = runShell(steps, "docker --version")
    if (dockerHome) {
        tools['docker'] = [name: 'Docker', home: dockerHome, version: dockerVersion]
    }

    return tools
}

def configureTools(steps) {
    def jenkinsInstance = jenkins.model.Jenkins.get()

    def configXmlFile = jenkinsInstance.getRootDir().toString() + "/config.xml"
    def xmlParser = new XmlParser()
    def configXml = xmlParser.parse(new File(configXmlFile))

    def tools = detectTools(steps)

    def toolLocationsNode = configXml.'toolLocations'[0]
    if (!toolLocationsNode) {
        toolLocationsNode = new Node(configXml, 'toolLocations')
    } else {
        toolLocationsNode.children().clear()
    }

    tools.each { key, value ->
        if (value.home) {
            def toolNode = new Node(toolLocationsNode, 'toolLocation')
            new Node(toolNode, 'name', value.name)
            new Node(toolNode, 'home', value.home)
        }
    }

    // Save the updated config.xml
    def writer = new StringWriter()
    groovy.xml.XmlNodePrinter printer = new groovy.xml.XmlNodePrinter(new PrintWriter(writer))
    printer.setPreserveWhitespace(true)
    printer.print(configXml)

    new File(configXmlFile).write(writer.toString())

    jenkinsInstance.reload()

    println("Configured tools:")
    tools.each { key, value ->
        println(" - ${value.name} at ${value.home} (version: ${value.version})")
    }
}

def toolConfiguration() {
    // 'steps' is implicitly available inside pipeline 'script' block
    configureTools(this)
}

return this
