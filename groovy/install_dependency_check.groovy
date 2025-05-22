import groovy.json.JsonSlurper

class DependencyCheckInstaller {
    def script
    def jenkinsUrl = System.getenv('JENKINS_URL') ?: 'http://localhost:8080'
    def credId = System.getenv('JENKINS_CREDS_ID') ?: 'jenkins-cred'
    def nvdDir = "/var/lib/jenkins/dependency-check-data"
    def owaspImage = "owasp/dependency-check:latest"

    DependencyCheckInstaller(script) {
        this.script = script
    }

    def installDependencyCheck() {
        script.echo "Starting OWASP Dependency-Check installation..."

        // Create NVD data directory (needs proper permissions)
        script.sh "mkdir -p ${nvdDir}"

        // Pull latest OWASP Dependency-Check Docker image
        script.sh "docker pull ${owaspImage}"

        // Run container to update NVD DB with verbose output
        script.sh """
            docker run --rm \\
                -v ${nvdDir}:/usr/share/dependency-check/data \\
                ${owaspImage} \\
                --updateonly --verbose
        """

        script.echo "NVD database updated and cached at ${nvdDir}"

        // Configure Jenkins tool to use this local NVD DB
        configureJenkinsTool()
    }

    def configureJenkinsTool() {
        script.echo "Configuring Jenkins Dependency-Check tool..."

        // Use Jenkins credentials: username/password
        script.withCredentials([script.usernamePassword(credentialsId: credId,
            usernameVariable: 'JENKINS_USER', passwordVariable: 'JENKINS_PASS')]) {

            def user = script.env.JENKINS_USER
            def pass = script.env.JENKINS_PASS
            def basicAuth = "${user}:${pass}".bytes.encodeBase64().toString()

            def httpGet = { urlStr ->
                def url = new URL(urlStr)
                def conn = url.openConnection()
                conn.setRequestProperty('Authorization', "Basic ${basicAuth}")
                conn.connect()
                if (conn.responseCode != 200) {
                    script.error "GET failed: ${urlStr} (HTTP ${conn.responseCode})"
                }
                return conn.inputStream.text
            }

            def httpPost = { urlStr, body, contentType='application/xml' ->
                def url = new URL(urlStr)
                def conn = url.openConnection()
                conn.setRequestProperty('Authorization', "Basic ${basicAuth}")
                conn.setRequestProperty('Content-Type', contentType)
                conn.setDoOutput(true)
                conn.setRequestMethod('POST')
                conn.outputStream.withWriter { writer -> writer << body }
                if (conn.responseCode < 200 || conn.responseCode >= 300) {
                    script.error "POST failed: ${urlStr} (HTTP ${conn.responseCode})"
                }
                return conn.inputStream.text
            }

            // Fetch current tool config XML
            def configUrl = "${jenkinsUrl}/tool/dependency-check/installations/config.xml"
            def configXml = ''
            try {
                configXml = httpGet(configUrl)
                script.echo "Fetched existing Dependency-Check config.xml"
            } catch (Exception e) {
                script.echo "No existing Dependency-Check config found, will create new."
                // Start from minimal config if not exist
                configXml = """<installations class="java.util.Collections$EmptyList"/>"""
            }

            // Parse XML to update/add installation
            def parser = new XmlParser(false, false)
            def root = parser.parseText(configXml)

            // Clear existing installations and add one with local NVD
            def installationsNode = root
            if (root.name() != 'installations') {
                installationsNode = root.'installations'[0]
                if (installationsNode == null) {
                    installationsNode = new Node(root, 'installations')
                }
            }

            installationsNode.replaceNode {
                installations(class: 'java.util.Collections$SingletonList') {
                    'org.jenkinsci.plugins.DependencyCheck.DependencyCheckInstallation' {
                        name('LocalNVD')
                        home(nvdDir)
                        properties(class: 'java.util.Collections$EmptyList')
                    }
                }
            }

            // Serialize XML back to string
            def writer = new StringWriter()
            def printer = new XmlNodePrinter(new PrintWriter(writer))
            printer.setPreserveWhitespace(true)
            printer.print(root)
            def newConfigXml = writer.toString()

            // POST updated config back to Jenkins
            def updateUrl = "${jenkinsUrl}/tool/dependency-check/installations/config.xml"
            httpPost(updateUrl, newConfigXml, 'application/xml')

            script.echo "Dependency-Check tool configured with local NVD directory at ${nvdDir}"
        }
    }

    def cleanupDependencyCheck() {
        script.echo "Cleaning up OWASP Dependency-Check data directory..."

        // Remove cached NVD data directory
        script.sh "rm -rf ${nvdDir}"

        script.echo "Cleanup complete."
    }
}

return new DependencyCheckInstaller(this)
