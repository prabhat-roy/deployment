import jenkins.model.*
import hudson.tools.*
import hudson.util.*
import jenkins.install.*

class ToolConfigurator {
  
  @NonCPS
  def getToolHome(String exe) {
    def proc = "which ${exe}".execute()
    proc.waitFor()
    if (proc.exitValue() != 0) return null
    def path = proc.text.trim()
    if (!path) return null
    // Usually tool home is parent dir of bin, so go two levels up from exe path
    def homeProc = "readlink -f ${path}".execute()
    homeProc.waitFor()
    def realPath = homeProc.text.trim()
    def home = new File(realPath).parentFile.parent
    return home?.absolutePath
  }
  
  @NonCPS
  def getVersion(String command, String regex) {
    def proc = command.execute()
    proc.waitFor()
    if (proc.exitValue() != 0) return "unknown"
    def output = proc.text.trim()
    def matcher = (output =~ regex)
    return matcher ? matcher[0][1] : "unknown"
  }
  
  def toolConfiguration() {
    def jenkins = Jenkins.instance

    // Detect Maven
    def mavenHome = getToolHome("mvn")
    def mavenVersion = getVersion("mvn -v", /Apache Maven (\d+\.\d+\.\d+)/)
    
    // Detect JDK
    def javaHome = getToolHome("java")
    def javaVersion = getVersion("java -version 2>&1", /version "(\d+(\.\d+)+.*)"/)
    
    // Detect NodeJS
    def nodeHome = getToolHome("node")
    def nodeVersion = getVersion("node -v", /v(\d+\.\d+\.\d+)/)
    
    // Detect Gradle
    def gradleHome = getToolHome("gradle")
    def gradleVersion = getVersion("gradle -v", /Gradle (\d+\.\d+(\.\d+)?)/)
    
    // Detect Ant
    def antHome = getToolHome("ant")
    def antVersion = getVersion("ant -version", /version (\d+\.\d+\.\d+)/)

    // Helper to create or update tool installations:
    def configureToolInstallation = { toolType, toolNamePrefix, homePath, version ->
      if (!homePath) {
        println "${toolNamePrefix} not found on system, skipping..."
        return
      }
      def name = "${toolNamePrefix}-${version}"
      println "Configuring ${toolType} tool: ${name} at ${homePath}"
      
      def descriptor = jenkins.getDescriptorByType(
        (Class) Class.forName("hudson.tools.${toolType.capitalize()}Installer"))?.getClass()?.getEnclosingClass()
      
      // For example, Maven installations
      def toolsList = jenkins.getDescriptorByType(
        (Class) Class.forName("hudson.tools.${toolType.capitalize()}Installation"))?.getInstallations()

      def updated = false
      
      // Search for existing installation with same name
      def existing = toolsList.find { it.name == name }
      if (existing) {
        if (existing.home != homePath) {
          println "Updating ${toolType} installation ${name} home path from ${existing.home} to ${homePath}"
          existing.home = homePath
          updated = true
        } else {
          println "${toolType} installation ${name} already configured"
        }
      } else {
        println "Adding new ${toolType} installation: ${name}"
        def constructor = Class.forName("hudson.tools.${toolType.capitalize()}Installation")
          .getConstructor(String.class, String.class, List.class)
        def newInstallation = constructor.newInstance(name, homePath, Collections.emptyList())
        def newTools = toolsList + newInstallation
        // Set new installations back
        def desc = jenkins.getDescriptorByType(Class.forName("hudson.tools.${toolType.capitalize()}Installation"))
        desc.setInstallations((hudson.tools.ToolInstallation[]) newTools)
        updated = true
      }
      
      if (updated) {
        jenkins.save()
        println "${toolType} tools updated and saved"
      }
    }
    
    // Configure all tools
    configureToolInstallation("maven", "Maven", mavenHome, mavenVersion)
    configureToolInstallation("jdk", "JDK", javaHome, javaVersion)
    configureToolInstallation("nodeJS", "NodeJS", nodeHome, nodeVersion)
    configureToolInstallation("gradle", "Gradle", gradleHome, gradleVersion)
    configureToolInstallation("ant", "Ant", antHome, antVersion)
  }
}

return new ToolConfigurator()
