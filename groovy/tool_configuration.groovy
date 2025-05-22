// Fix: Escape $ in shell script strings or use triple quotes with ${}

// Updated groovy/tool_configuration.groovy

import jenkins.model.Jenkins
import hudson.tools.JDK
import hudson.tasks.Maven$MavenInstallation
import hudson.tasks.Ant$AntInstallation
import org.jenkinsci.plugins.gradle.GradleInstallation
import jenkins.plugins.nodejs.tools.NodeJSInstallation
import com.nirima.jenkins.plugins.docker.DockerTool

class ToolConfiguration {
    def steps
    def env

    ToolConfiguration(steps, env) {
        this.steps = steps
        this.env = env
    }

    def toolConfiguration() {
        def tools = [:]

        // Use triple-double quotes and ${} to escape $ in shell commands
        def jdkHome = steps.sh(script: """dirname \$(dirname \$(readlink -f \$(which java)))""", returnStdout: true).trim()
        def mavenHome = steps.sh(script: """dirname \$(dirname \$(readlink -f \$(which mvn)))""", returnStdout: true).trim()
        def gradleHome = steps.sh(script: """dirname \$(dirname \$(readlink -f \$(which gradle)))""", returnStdout: true).trim()
        def antHome = steps.sh(script: """dirname \$(dirname \$(readlink -f \$(which ant)))""", returnStdout: true).trim()
        def nodeHome = steps.sh(script: """dirname \$(readlink -f \$(which node))""", returnStdout: true).trim()
        def dockerHome = steps.sh(script: """dirname \$(readlink -f \$(which docker))""", returnStdout: true).trim()

        tools['jdk'] = [name: 'jdk', home: jdkHome]
        tools['maven'] = [name: 'maven', home: mavenHome]
        tools['gradle'] = [name: 'gradle', home: gradleHome]
        tools['ant'] = [name: 'ant', home: antHome]
        tools['nodejs'] = [name: 'nodejs', home: nodeHome]
        tools['docker'] = [name: 'docker', home: dockerHome]

        steps.echo "Detected tools: ${tools}"

        def jenkinsInstance = Jenkins.get()

        def jdkDescriptor = jenkinsInstance.getDescriptorByType(JDK.DescriptorImpl)
        def jdks = [new JDK(tools['jdk'].name, tools['jdk'].home)]
        jdkDescriptor.setInstallations(jdks.toArray(new JDK[0]))
        jdkDescriptor.save()

        def mavenDescriptor = jenkinsInstance.getDescriptorByType(MavenInstallation.class)
        def mavenTools = [new MavenInstallation(tools['maven'].name, tools['maven'].home, null)]
        mavenDescriptor.setInstallations(mavenTools.toArray(new MavenInstallation[0]))
        mavenDescriptor.save()

        def gradleDescriptor = jenkinsInstance.getDescriptorByType(GradleInstallation.class)
        def gradleTools = [new GradleInstallation(tools['gradle'].name, tools['gradle'].home, null)]
        gradleDescriptor.setInstallations(gradleTools.toArray(new GradleInstallation[0]))
        gradleDescriptor.save()

        def antDescriptor = jenkinsInstance.getDescriptorByType(AntInstallation.class)
        def antTools = [new AntInstallation(tools['ant'].name, tools['ant'].home, null)]
        antDescriptor.setInstallations(antTools.toArray(new AntInstallation[0]))
        antDescriptor.save()

        def nodeDescriptor = jenkinsInstance.getDescriptorByType(NodeJSInstallation.class)
        def nodeTools = [new NodeJSInstallation(tools['nodejs'].name, tools['nodejs'].home, [], null)]
        nodeDescriptor.setInstallations(nodeTools.toArray(new NodeJSInstallation[0]))
        nodeDescriptor.save()

        def dockerDescriptor = jenkinsInstance.getDescriptorByType(DockerTool.class)
        def dockerTools = [new DockerTool(tools['docker'].name, tools['docker'].home)]
        dockerDescriptor.setInstallations(dockerTools.toArray(new DockerTool[0]))
        dockerDescriptor.save()

        steps.echo "Jenkins tools configured successfully."
    }
}

return new ToolConfiguration(steps, env)
