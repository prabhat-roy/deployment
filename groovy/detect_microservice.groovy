class MicroserviceLister implements Serializable {
    def steps

    MicroserviceLister(steps) {
        this.steps = steps
    }

    List<String> getAllServices(String baseDir = 'src') {
        def output = steps.sh(
            script: "find ${baseDir} -mindepth 1 -maxdepth 1 -type d -exec basename {} \\; | sort",
            returnStdout: true
        ).trim()
        def services = output ? output.split("\n") as List : []
        steps.echo "📦 Discovered Microservices: ${services.join(', ')}"
        return services
    }

    void writeServicesToEnv(String envFile = 'Jenkins.env', String baseDir = 'src') {
        def services = getAllServices(baseDir)
        if (services.isEmpty()) {
            steps.echo "⚠️ No microservices found under '${baseDir}'"
            return
        }

        def line = "SERVICES=" + services.join(',')
        def lines = []

        if (steps.fileExists(envFile)) {
            lines = steps.readFile(envFile).readLines()
            def updated = false
            lines = lines.collect {
                if (it.startsWith("SERVICES=")) {
                    updated = true
                    return line
                }
                return it
            }
            if (!updated) {
                lines.add(line)
            }
        } else {
            lines = [line]
        }

        steps.writeFile file: envFile, text: lines.join('\n') + '\n'
        steps.echo "✅ Microservices list saved to ${envFile}"
    }
}

return new MicroserviceLister(this)
