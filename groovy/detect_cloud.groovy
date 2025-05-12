// Detect Cloud Provider Method
def detectCloudProvider() {
    try {
        echo "🔍 Detecting Cloud Provider..."

        // Check for AWS (EC2)
        if (fileExists('/sys/hypervisor/uuid')) {
            def uuid = readFile('/sys/hypervisor/uuid')
            if (uuid.startsWith('ec2')) {
                echo "☁️ Detected AWS"
                return 'AWS'
            }
        }

        // Check for GCP
        if (fileExists('/sys/class/dmi/id/product_name')) {
            def product = readFile('/sys/class/dmi/id/product_name')
            if (product.contains('Google')) {
                echo "☁️ Detected GCP"
                return 'GCP'
            }
        }

        // Check for Azure
        if (fileExists('/var/lib/waagent') || fileExists('/var/log/waagent.log')) {
            echo "☁️ Detected Azure"
            return 'AZURE'
        }

        echo "⚠️ Cloud Provider Unknown"
        return 'UNKNOWN'  // Default to unknown if no match found
    } catch (Exception e) {
        // In case of any errors (e.g., file access issues), return UNKNOWN
        echo "❌ Error detecting cloud provider: ${e.message}"
        return 'UNKNOWN'
    }
}

// Method to detect and save cloud provider
def detectAndSaveCloudProvider() {
    def cloud = detectCloudProvider()  // Detect cloud
    echo "🌐 Cloud Provider: ${cloud}"

    env.CLOUD_PROVIDER = cloud  // Export for Jenkins pipeline

    def envFile = 'Jenkins.env'
    def updated = false
    def lines = []

    if (fileExists(envFile)) {
        lines = readFile(envFile).readLines()
        lines = lines.collect { line ->
            if (line.startsWith('CLOUD_PROVIDER=')) {
                updated = true
                return "CLOUD_PROVIDER=${cloud}"
            }
            return line
        }
    }

    if (!updated) {
        lines.add("CLOUD_PROVIDER=${cloud}")
    }

    writeFile file: envFile, text: lines.join('\n') + '\n'
    echo "✅ CLOUD_PROVIDER=${cloud} saved to Jenkins.env"
}

// Return object for method access in Jenkinsfile
return this
