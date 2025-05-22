import java.net.URLEncoder

def configureTools(steps, env) {
    def jenkinsUrl = env.JENKINS_URL
    def credsId = env.JENKINS_CREDS_ID
    if (!jenkinsUrl || !credsId) {
        error "JENKINS_URL or JENKINS_CREDS_ID environment variables not set"
    }

    def tools = detectTools(steps)
    println "Detected tools: ${tools}"

    def groovyScript = """
        import jenkins.model.*
        import groovy.xml.*
        import javax.xml.transform.stream.StreamSource
        import java.io.StringReader
        import java.io.StringWriter
        import java.io.PrintWriter

        def jenkins = Jenkins.instance
        def toolsMap = [:]
        ${tools.collect { k, v -> "toolsMap['${v.name}'] = '${v.home}'" }.join('\n')}
        
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
        def printer = new XmlNodePrinter(new PrintWriter(writer))
        printer.print(config)
        jenkins.updateByXml(new StreamSource(new StringReader(writer.toString())))
        jenkins.save()
        return "Tools updated via script"
    """

    def encodedScript = URLEncoder.encode(groovyScript, "UTF-8")
    def requestBody = "script=${encodedScript}"

    def response = steps.httpRequest(
        httpMode: 'POST',
        acceptType: 'APPLICATION_JSON',
        authentication: credsId,
        contentType: 'APPLICATION_FORM',
        requestBody: requestBody,
        url: "${jenkinsUrl}/scriptText"
    )

    println "Jenkins response: ${response.content}"
}
