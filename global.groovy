def loadGlobalEnv() {
    echo "Loading global environment variables from global.env..."

    def envFile = readFile 'global.env'
    envFile.split("\n").each { line ->
        if (line.trim() && !line.startsWith("#")) {
            def parts = line.split("=", 2)
            if (parts.length == 2) {
                def key = parts[0].trim()
                def value = parts[1].trim()
                echo "Setting ${key} from global.env"
                env."${key}" = value
            }
        }
    }
}
