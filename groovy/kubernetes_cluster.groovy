def manageKubernetes(String action) {
    def cloud = env.CLOUD_PROVIDER?.toLowerCase()

    if (!cloud) {
        error "❌ CLOUD_PROVIDER environment variable is not set!"
    }

    if (action != 'create' && action != 'destroy') {
        error "❌ Invalid action '${action}'. Allowed values: create, destroy"
    }

    def tfAction = (action == 'destroy') ? 'destroy' : 'apply'

    def scriptMap = [
        'aws'  : 'shell_script/eks.sh',
        'azure': 'shell_script/aks.sh',
        'gcp'  : 'shell_script/gke.sh'
    ]

    def scriptPath = scriptMap[cloud]

    if (!scriptPath || !fileExists(scriptPath)) {
        error "❌ Shell script for cloud provider '${cloud}' not found at: ${scriptPath}"
    }

    def envVars = []

    switch (cloud) {
        case 'aws':
            envVars = ["TF_VAR_aws_region=${env.AWS_REGION}"]
            break
        case 'azure':
            envVars = ["TF_VAR_azure_region=${env.AZURE_REGION}"]
            break
        case 'gcp':
            envVars = [
                "TF_VAR_project_id=${env.GOOGLE_PROJECT}",
                "TF_VAR_gcp_region=${env.GOOGLE_REGION}"
            ]
            break
    }

    echo "🚀 Executing ${scriptPath} with action '${tfAction.toUpperCase()}'..."

    withEnv(envVars) {
        sh """
            chmod +x ${scriptPath}
            ${scriptPath} ${tfAction}
        """
    }
}

return this
