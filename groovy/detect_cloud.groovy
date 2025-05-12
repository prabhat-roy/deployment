// groovy/detect_cloud.groovy

// Detect Cloud Provider Method
def detectCloudProvider() {
    try {
        if (fileExists('/sys/hypervisor/uuid') &&
            readFile('/sys/hypervisor/uuid').startsWith('ec2')) {
            return 'AWS'
        }

        if (fileExists('/sys/class/dmi/id/product_name') &&
            readFile('/sys/class/dmi/id/product_name').contains('Google')) {
            return 'GCP'
        }

        if (fileExists('/var/lib/waagent') || fileExists('/var/log/waagent.log')) {
            return 'AZURE'
        }

        return 'UNKNOWN'
    } catch (Exception e) {
        return 'UNKNOWN'
    }
}

// Method to detect and save cloud provider
def detectAndSaveCloudProvider() {
    def cloud = detectCloudProvider()  // Call the method to detect cloud provider
    echo "Detected Cloud Provider: ${cloud}"

    // Set as an env var for the current pipeline
    env.CLOUD_PROVIDER = cloud

    // Update or add CLOUD_PROVIDER in Jenkins.env
    def envFile = 'Jenkins.env'

    if (fileExists(envFile)) {
        def lines = readFile(envFile).readLines()
        def updated = false

        // Replace CLOUD_PROVIDER if it exists
        lines = lines.collect { line ->
            if (line.startsWith('CLOUD_PROVIDER=')) {
                updated = true
                return "CLOUD_PROVIDER=${cloud}"
            }
            return line
        }

        // Add it if it wasn't found
        if (!updated) {
            lines.add("CLOUD_PROVIDER=${cloud}")
        }

        writeFile file: envFile, text: lines.join('\n') + '\n'
    } else {
        // Create file if it doesn't exist
        writeFile file: envFile, text: "CLOUD_PROVIDER=${cloud}\n"
    }

    echo "✅ CLOUD_PROVIDER saved to Jenkins.env"
}

return this  // Return the current object to make the methods accessible
