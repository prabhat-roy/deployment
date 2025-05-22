import groovy.xml.*
import groovy.json.*
import jenkins.model.*
import hudson.model.*
import java.util.regex.*

class JenkinsToolConfigurator implements Serializable {
    def steps
    def jenkinsUrl
    def credsId

    JenkinsToolConfigurator(steps) {
        this.steps = steps
        this.jenkinsUrl = System.getenv('JENKINS_URL') ?: 'http://localhost:8080'
        this.credsId = System.getenv('JENKINS_CREDS_ID') ?: 'jenkins-cred'
    }

    def toolConfiguration() {
        steps.echo "Starting Jenkins tool configuration..."

        def detectedTools = [
            ant   : [:],
            maven : [:],
            gradle: [:],
            nodejs: [:],
            docker: [:],
            jdk   : [:]
        ]

        // Detect Ant
        detectTool('ant', 'ant -version', ~/Apache Ant \(.*\) version ([\d.]+)/, /which ant/, detectedTools.ant)

        // Detect Maven
        detectTool('maven', 'mvn -version', ~/Apache Maven ([\d.]+)/, /which mvn/, detectedTools.maven)

        // Detect Gradle
        detectTool('gradle', 'gradle -version', ~/Gradle ([\d.]+)/, /which gradle/, detectedTools.gradle)

        // Detect NodeJS
        detectTool('nodejs', 'node -v', ~/v([\d.]+)/, /which node/, detectedTools.nodejs)

        // Detect Docker
        detectTool('docker', 'docker --version', ~/Docker version ([\d.]+)/, /which docker/, detectedTools.docker)

        // Detect JDK (special)
        def (jdkVersion, jdkPath) = detectJDK()
        if (jdkVersion && jdkPath) {
            detectedTools.jdk["jdk-${jdkVersion}"] = jdkPath
        }

        steps.echo "Detected tools and versions: ${detectedTools}"

        // Fetch Jenkins current config.xml
        def configXml = fetchConfigXml()

        // Update tools in config.xml
        def updatedXml = updateToolsInConfig(configXml, detectedTools)

        // Post updated config.xml to Jenkins
        def status = postConfigXml(updatedXml)

        if (status == 200 || status == 302) {
            steps.echo "Tools configured successfully in Jenkins!"
        } else {
            steps.error "Failed to update Jenkins config.xml, HTTP status: ${status}"
        }
    }

    // Helper to detect tools generically
    private void detectTool(String toolName, String versionCmd, Pattern versionPattern, String pathCmd, Map outMap) {
        try {
            def versionOutput = steps.sh(script: versionCmd, returnStdout: true).trim()
            def pathOutput = steps.sh(script: pathCmd, returnStdout: true).trim()
            def matcher = (versionOutput =~ versionPattern)
            if (matcher) {
                def version = matcher[0][1]
                def pathDir = steps.sh(script: "dirname ${pathOutput}", returnStdout: true).trim()
                outMap["${toolName}-${version}"] = pathDir
            } else {
                steps.echo "Version pattern not matched for ${toolName}"
            }
        } catch (Exception e) {
            steps.echo "Failed to detect ${toolName}: ${e.message}"
        }
    }

    // Special JDK detection
    private List detectJDK() {
        try {
            // Get Java executable path and resolve home
            def javaBin = steps.sh(script: 'readlink -f $(which java)', returnStdout: true).trim()
            def javaHome = javaBin.replaceAll(/\/bin\/java$/, '')
            def versionOutput = steps.sh(script: "${javaHome}/bin/java -version 2>&1", returnStdout: true).trim()
            def matcher = (versionOutput =~ /version \"(\d+(\.\d+)*).*\"/)
            def version = matcher ? matcher[0][1] : null
            if (!version) {
                steps.echo "Could not parse JDK version from output: ${versionOutput}"
                return [null, null]
            }
            return [version, javaHome]
        } catch (Exception e) {
            steps.echo "Failed to detect JDK: ${e.message}"
            return [null, null]
        }
    }

    // Fetch current Jenkins config.xml (GET /config.xml)
    private String fetchConfigXml() {
        def script = """
            import jenkins.model.*
            return Jenkins.instance.getDescriptorByType(jenkins.model.JenkinsLocationConfiguration.class).getConfigFile().asString()
        """
        // We cannot run Groovy directly in pipeline to get config.xml, so do HTTP GET
        def url = "${jenkinsUrl}/config.xml"
        return httpGet(url)
    }

    // Post updated config.xml (POST /config.xml)
    private int postConfigXml(String configXml) {
        def url = "${jenkinsUrl}/config.xml"
        return httpPost(url, configXml)
    }

    // HTTP GET helper with basic auth from Jenkins credentials
    private String httpGet(String url) {
        def authHeader = getAuthHeader()
        def connection = new URL(url).openConnection()
        connection.setRequestProperty("Authorization", authHeader)
        connection.setRequestMethod("GET")
        connection.setDoOutput(false)
        return connection.inputStream.text
    }

    // HTTP POST helper with basic auth from Jenkins credentials
    private int httpPost(String url, String body) {
        def authHeader = getAuthHeader()
        def connection = new URL(url).openConnection()
        connection.setRequestProperty("Authorization", authHeader)
        connection.setRequestProperty("Content-Type", "application/xml")
        connection.setRequestMethod("POST")
        connection.doOutput = true
        connection.outputStream.withWriter { it << body }
        return connection.responseCode
    }

    // Get base64 auth header from Jenkins credentials
    private String getAuthHeader() {
        def username = ''
        def password = ''
        steps.withCredentials([steps.usernamePassword(credentialsId: credsId, usernameVariable: 'USER', passwordVariable: 'PASS')]) {
            username = steps.env.USER
            password = steps.env.PASS
        }
        def userpass = "${username}:${password}".bytes.encodeBase64().toString()
        return "Basic ${userpass}"
    }

    // Update Jenkins config.xml with detected tools
    private String updateToolsInConfig(String configXml, Map toolsMap) {
        def parser = new XmlParser(false, false)
        def root = parser.parseText(configXml)

        // Update JDK installations
        def jdkDesc = root.'hudson.model.JDK_-DescriptorImpl'[0]
        if (!jdkDesc) jdkDesc = root.appendNode('hudson.model.JDK_-DescriptorImpl')
        def jdkInstalls = jdkDesc.installations[0] ?: jdkDesc.appendNode('installations')
        jdkInstalls.replaceBody('')
        toolsMap.jdk.each { name, home ->
            def jdkNode = jdkInstalls.appendNode('jdk')
            jdkNode.appendNode('name', name)
            jdkNode.appendNode('home', home)
            jdkNode.appendNode('properties')
        }

        // Update Ant installations
        def antDesc = root.'hudson.tasks.Ant$AntDescriptor'[0]
        if (!antDesc) antDesc = root.appendNode('hudson.tasks.Ant$AntDescriptor')
        def antInstalls = antDesc.installations[0] ?: antDesc.appendNode('installations')
        antInstalls.replaceBody('')
        toolsMap.ant.each { name, home ->
            def antNode = antInstalls.appendNode('hudson.tasks.Ant')
            antNode.appendNode('name', name)
            antNode.appendNode('home', home)
            antNode.appendNode('properties')
        }

        // Update Maven installations
        def mavenDesc = root.'hudson.tasks.Maven$MavenInstallationDescriptor'[0]
        if (!mavenDesc) mavenDesc = root.appendNode('hudson.tasks.Maven$MavenInstallationDescriptor')
        def mavenInstalls = mavenDesc.installations[0] ?: mavenDesc.appendNode('installations')
        mavenInstalls.replaceBody('')
        toolsMap.maven.each { name, home ->
            def mavenNode = mavenInstalls.appendNode('hudson.tasks.Maven$MavenInstallation')
            mavenNode.appendNode('name', name)
            mavenNode.appendNode('home', home)
            mavenNode.appendNode('properties')
        }

        // Update Gradle installations
        def gradleDesc = root.'hudson.plugins.gradle.GradleInstallation$DescriptorImpl'[0]
        if (!gradleDesc) gradleDesc = root.appendNode('hudson.plugins.gradle.GradleInstallation$DescriptorImpl')
        def gradleInstalls = gradleDesc.installations[0] ?: gradleDesc.appendNode('installations')
        gradleInstalls.replaceBody('')
        toolsMap.gradle.each { name, home ->
            def gradleNode = gradleInstalls.appendNode('hudson.plugins.gradle.GradleInstallation')
            gradleNode.appendNode('name', name)
            gradleNode.appendNode('home', home)
            gradleNode.appendNode('properties')
        }

        // Update NodeJS installations
        def nodeDesc = root.'jenkins.plugins.nodejs.tools.NodeJSInstallation.DescriptorImpl'[0]
        if (!nodeDesc) nodeDesc = root.appendNode('jenkins.plugins.nodejs.tools.NodeJSInstallation.DescriptorImpl')
        def nodeInstalls = nodeDesc.installations[0] ?: nodeDesc.appendNode('installations')
        nodeInstalls.replaceBody('')
        toolsMap.nodejs.each { name, home ->
            def nodeNode = nodeInstalls.appendNode('jenkins.plugins.nodejs.tools.NodeJSInstallation')
            nodeNode.appendNode('name', name)
            nodeNode.appendNode('home', home)
            nodeNode.appendNode('properties')
        }

        // Update Docker installations (dockerTool)
        def dockerDesc = root.'com.nirima.jenkins.plugins.docker.DockerTool.DescriptorImpl'[0]
        if (!dockerDesc) dockerDesc = root.appendNode('com.nirima.jenkins.plugins.docker.DockerTool.DescriptorImpl')
        def dockerInstalls = dockerDesc.installations[0] ?: dockerDesc.appendNode('installations')
        dockerInstalls.replaceBody('')
        toolsMap.docker.each { name, home ->
            def dockerNode = dockerInstalls.appendNode('com.nirima.jenkins.plugins.docker.DockerTool')
            dockerNode.appendNode('name', name)
            dockerNode.appendNode('executable', "${home}/docker")
            dockerNode.appendNode('properties')
        }

        // Serialize back to XML string
        def writer = new StringWriter()
        XmlNodePrinter printer = new XmlNodePrinter(new PrintWriter(writer))
        printer.preserveWhitespace = true
        printer.print(root)
        return writer.toString()
    }
}
return new JenkinsToolConfigurator(this)
