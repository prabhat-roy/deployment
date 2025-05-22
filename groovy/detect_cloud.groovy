class CloudProviderDetector implements Serializable {
    def steps

    CloudProviderDetector(steps) {
        this.steps = steps
    }

    String detectCloudProvider() {
        try {
            steps.echo "🔍 Detecting Cloud Provider..."

            // AWS
            if (steps.fileExists('/sys/hypervisor/uuid')) {
                def uuid = steps.readFile('/sys/hypervisor/uuid')
                if (uuid.startsWith('ec2')) {
                    steps.echo "☁️ Detected AWS"
                    return 'AWS'
                }
            }

            // GCP
            if (steps.fileExists('/sys/class/dmi/id/product_name')) {
                def product = steps.readFile('/sys/class/dmi/id/product_name')
                if (product.contains('Google')) {
                    steps.echo "☁️ Detected GCP"
                    return 'GCP'
                }
            }

            // Azure
            if (steps.fileExists('/var/lib/waagent') || steps.fileExists('/var/log/waagent.log')) {
                steps.echo "☁️ Detected Azure"
                return 'AZURE'
            }

            steps.echo "⚠️ Cloud Provider Unknown"
            return 'UNKNOWN'
        } catch (Exception e) {
            steps.echo "❌ Error detecting cloud provider: ${e.message}"
            return 'UNKNOWN'
        }
    }

    void detectAndSaveCloudProvider(String envFile = 'Jenkins.env') {
        def cloud = detectCloudProvider()
        steps.echo "🌐 Cloud Provider: ${cloud}"

        steps.env.CLOUD_PROVIDER = cloud

        def updated = false
        def lines = []

        if (steps.fileExists(envFile)) {
            lines = steps.readFile(envFile).readLines()
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

        steps.writeFile file: envFile, text: lines.join('\n') + '\n'
        steps.echo "✅ CLOUD_PROVIDER=${cloud} saved to ${envFile}"
    }
}

return new CloudProviderDetector(this)
