def detectAndSaveCloudProvider() {
    def cloud = detectCloudProvider()
    echo "Detected Cloud Provider: ${cloud}"

    // Set it as an env var for the pipeline
    env.CLOUD_PROVIDER = cloud

    // Also write it to a file for reuse
    writeFile file: 'cloud.env', text: "CLOUD_PROVIDER=${cloud}\n"
}

// Helper method for cloud detection logic
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

return this
