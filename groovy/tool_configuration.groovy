import groovy.json.JsonOutput
import groovy.json.JsonSlurper

def runShell(steps, cmd) {
    try {
        return steps.sh(script: cmd, returnStdout: true).trim()
    } catch (err) {
        return null
    }
}

def detectTools(steps) {
    def tools = [:]

    def javaHome = runShell(steps, "dirname \$(dirname \$(readlink -f \$(which java)))")
    if(javaHome) {
        tools['jdk'] = [name: 'jdk', home: javaHome, type: 'jdk']
    }

    def mvnHome = runShell(steps, "dirname \$(dirname \$(readlink -f \$(which mvn)))")
    if(mvnHome) {
        tools['maven'] = [name: 'maven', home: mvnHome, type: 'maven']
    }

    def gradleHome = runShell(steps, "dirname \$(dirname \$(readlink -f \$(which gradle)))")
    if(gradleHome) {
        tools['gradle'] = [name: 'gradle', home: gradleHome, type: 'gradle']
    }

    def antHome = runShell(steps, "dirname \$(dirname \$(readlink -f \$(which ant)))")
    if(antHome) {
        tools['ant'] = [name: 'ant', home: antHome, type: 'ant']
    }

    def nodeHome = runShell(steps, "dirname \$(dirname \$(readlink -f \$(which node)))")
    if(nodeHome) {
        tools['nodejs'] = [name: 'nodejs', home: nodeHome, type: 'nodejs']
    }

    def dockerHome = runShell(steps, "dirname \$(dirname \$(readlink -f \$(which docker)))")
    if(dockerHome) {
        tools['docker'] = [name: 'docker', home: dockerHome, type: 'docker']
    }

    return tools
}

def configureTools(steps, env) {
    def jenkinsUrl = env.JENKINS_URL
    def credsId = env.JENKINS_CREDS_ID
    if(!jenkinsUrl || !credsId) {
        error "JENKINS_URL or JENKINS_CREDS_ID environment variables not set"
    }

    def tools = detectTools(steps)
    println "Detected tools: ${tools}"

    // Prepare JSON payload or XML payload for Jenkins tool configuration
    // This example uses JSON to update toolLocations via Jenkins Script Console API
    // but in reality Jenkins doesn't expose a direct REST API for tool config
    // So this approach needs to call a Groovy script via /scriptText API or configure using CLI

    // Here we'll call /scriptText API with a Groovy script that updates tools on the Jenkins master

    def groovyScript = """
    import jenkins.model.*
    def jenkins = Jenkins.instance
    def toolsMap = [:]
    ${tools.collect { k,v -> "toolsMap['${v.name}'] = '${v.home}'" }.join('\n')}
    def configXml = jenkins.getConfigFile('tools').asString()
    def parser = new XmlParser()
    def config = parser.parseText(configXml)
    def toolLocationsNode = config.toolLocations ? config.toolLocations[0] : config.appendNode('toolLocations')
    toolLocationsNode.children().clear()
    toolsMap.each { name, home ->
        def toolLocation = new Node(toolLocationsNode, 'toolLocation')
        new Node(toolLocation, 'name', name)
        new Node(toolLocation, 'home', home)
    }
    def writer = new StringWriter()
    def printer = new groovy.xml.XmlNodePrinter(new PrintWriter(writer))
    printer.print(config)
    jenkins.updateByXml(new StreamSource(new StringReader(writer.toString())))
    jenkins.save()
    return "Tools updated via script"
    """

    def encodedScript = groovyScript.bytes.encodeBase64().toString()

    def response = steps.httpRequest(
        httpMode: 'POST',
        acceptType: 'APPLICATION_JSON',
        authentication: credsId,
        contentType: 'APPLICATION_FORM',
        requestBody: "script=${java.net.URLEncoder.encode(groovyScript, 'UTF-8')}",
        url: "${jenkinsUrl}/scriptText"
    )
    println "Jenkins response: ${response.content}"
}

def toolConfiguration() {
    configureTools(this, this.env)
}

return this
