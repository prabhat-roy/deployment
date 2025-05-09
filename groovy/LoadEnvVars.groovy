def loadEnvVars(String filePath = 'groovy/Deployment.env') {
    def envMap = [:]
    if (!fileExists(filePath)) {
        error "[ERROR] .env file not found at: ${filePath}"
    }

    readFile(filePath).split('\n').each { line ->
        line = line.trim()
        if (line && !line.startsWith('#') && line.contains('=')) {
            def (key, val) = line.tokenize('=')
            val = val.trim().replaceAll(/^["']|["']$/, '')
            envMap[key.trim()] = val
        }
    }

    return envMap
}
return this
