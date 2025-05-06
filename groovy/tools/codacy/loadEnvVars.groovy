def call() {
    echo "📄 Loading Codacy environment variables..."
    def envFile = readFile 'groovy/tools/codacy/codacy.env'
    envFile.split("\n").each { line ->
        if (line.trim() && line.trim().startsWith("export ")) {
            def (key, value) = line.replace("export ", "").split("=", 2)
            env[key.trim()] = value.trim().replaceAll('"', '')
        }
    }
}
