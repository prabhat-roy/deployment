class ToolConfiguration {
    def steps
    def env

    ToolConfiguration(steps, env) {
        this.steps = steps
        this.env = env
    }

    def toolConfiguration() {
        def jenkinsUrl = env.JENKINS_URL ?: "http://localhost:8080"
        def credsId = env.JENKINS_CREDS_ID ?: "jenkins-cred"

        def tools = [
            jdk    : [name: "jdk",    detectCmd: "java -XshowSettings:properties -version 2>&1 | grep 'java.home' | awk '{print \$3}'"],
            maven  : [name: "maven",  detectCmd: "mvn -version | head -1 | awk '{print \$3}'", detectHomeCmd: "dirname \$(dirname \$(which mvn))"],
            gradle : [name: "gradle", detectCmd: "gradle -v | grep Gradle | awk '{print \$2}'", detectHomeCmd: "dirname \$(dirname \$(which gradle))"],
            ant    : [name: "ant",    detectCmd: "ant -version | awk '{print \$4}'", detectHomeCmd: "dirname \$(dirname \$(which ant))"],
            nodejs : [name: "nodejs", detectCmd: "node -v | sed 's/v//'", detectHomeCmd: "dirname \$(dirname \$(which node))"],
            docker : [name: "docker", detectCmd: "docker --version | awk '{print \$3}' | sed 's/,//'", detectHomeCmd: "dirname \$(which docker)"]
        ]

        def toolLocations = []

        tools.each { key, tool ->
            def version = ""
            def home = ""

            try {
                version = steps.sh(script: tool.detectCmd, returnStdout: true).trim()
                if (tool.containsKey('detectHomeCmd')) {
                    home = steps.sh(script: tool.detectHomeCmd, returnStdout: true).trim()
                }
            } catch (e) {
                steps.echo "Failed to detect ${tool.name} version or home: ${e}"
            }

            if (version && home) {
                steps.echo "Detected ${tool.name}: version=${version}, home=${home}"
                toolLocations << [name: tool.name, home: home]
            } else {
                steps.echo "Skipping ${tool.name} because version or home not found."
            }
        }

        def xmlrpc = new URL("${jenkinsUrl}/descriptorByName/hudson.tools.ToolDescriptor/configSubmit")
        def authString = steps.sh(script: "echo -n :${credsId} | base64", returnStdout: true).trim()

        // Because interacting with Jenkins API to update tools requires complex config xml manipulation
        // and authentication, usually this should be done outside pipeline or by script console.

        // This pipeline just outputs detected tools info.

        steps.echo "Detected Tools and paths to configure in Jenkins: ${toolLocations}"

        // You can extend here with your Jenkins CLI or REST API calls
        // to create or update the tool configurations.

        // Example placeholder:
        // toolLocations.each { tool ->
        //     steps.echo "Would configure tool ${tool.name} with path ${tool.home}"
        // }
    }
}

return new ToolConfiguration(steps, env)
