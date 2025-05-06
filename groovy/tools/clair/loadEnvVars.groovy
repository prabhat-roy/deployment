def call() {
    echo "📄 Loading Clair environment variables..."
    def envFile = readFile 'groovy/tools/clair/clair.env'
    envFile.split("\n").each { line ->
        if (line.trim() && line.trim().startsWith("export ")) {
            def (key, value) = line.replace("export ", "").split("=", 2)
            env[key.trim()] = value.trim().replaceAll('"', '')
        }
    }
}
