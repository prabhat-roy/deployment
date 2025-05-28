def manageRegistryCredential(String action = 'create') {
    def cloud = env.CLOUD_PROVIDER?.toLowerCase()
    def credId = "cloud-repo-login"
    def jenkinsUrl = "http://localhost:8080"
    def jenkinsCredId = "jenkins-cred" // Stored Jenkins credential
    def username, password, registryUrl

    if (!cloud) {
        error "❌ CLOUD_PROVIDER environment variable is not set!"
    }

    if (!(action in ['create', 'destroy'])) {
        error "❌ Invalid action '${action}'. Allowed: create, destroy"
    }

    withCredentials([usernamePassword(credentialsId: jenkinsCredId, usernameVariable: 'JENKINS_USER', passwordVariable: 'JENKINS_TOKEN')]) {

        if (action == 'destroy') {
            echo "🔥 Removing Jenkins credential: ${credId}"
            def script = """
                import com.cloudbees.plugins.credentials.*
                import com.cloudbees.plugins.credentials.domains.*
                import jenkins.model.*

                def store = Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()
                def creds = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
                    com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl.class,
                    Jenkins.instance,
                    null,
                    null
                )
                def target = creds.find { it.id == '${credId}' }
                if (target != null) {
                    store.removeCredentials(Domain.global(), target)
                    println("✅ Credential '${credId}' removed.")
                } else {
                    println("ℹ️ Credential '${credId}' not found. Nothing to remove.")
                }
            """

            sh """
                curl -s -X POST '${jenkinsUrl}/scriptText' \\
                  --user \$JENKINS_USER:\$JENKINS_TOKEN \\
                  --data-urlencode 'script=${script}'
            """
            return
        }

        // --- Credential creation path ---
        switch (cloud) {
            case 'aws':
                username = 'AWS'
                password = sh(script: "aws ecr get-login-password --region ${env.AWS_REGION}", returnStdout: true).trim()
                registryUrl = sh(script: "aws sts get-caller-identity --query 'Account' --output text", returnStdout: true).trim()
                registryUrl = "${registryUrl}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"
                break

            case 'azure':
                def acrName = sh(script: "terraform output -raw acr_name", returnStdout: true).trim()
                username = acrName
                password = sh(script: "az acr credential show -n ${acrName} --query 'passwords[0].value' -o tsv", returnStdout: true).trim()
                registryUrl = "${acrName}.azurecr.io"
                break

            case 'gcp':
                username = "_json_key"
                def keyFile = "gcp-sa-key.json"
                writeFile file: keyFile, text: sh(script: "cat ~/.config/gcloud/application_default_credentials.json", returnStdout: true).trim()
                password = readFile(keyFile).trim()
                registryUrl = "${env.GCP_REGION}-docker.pkg.dev"
                break

            default:
                error "❌ Unsupported CLOUD_PROVIDER: ${cloud}"
        }

        echo "🔐 Creating Jenkins credential for registry: ${registryUrl}"

        def script = """
            import com.cloudbees.plugins.credentials.*
            import com.cloudbees.plugins.credentials.domains.*
            import com.cloudbees.plugins.credentials.impl.*
            import jenkins.model.*

            def store = Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()
            def existing = CredentialsProvider.lookupCredentials(UsernamePasswordCredentialsImpl.class, Jenkins.instance, null, null).find { it.id == '${credId}' }

            if (existing != null) {
                println("✅ Credential '${credId}' already exists. Skipping creation.")
            } else {
                def cred = new UsernamePasswordCredentialsImpl(
                    CredentialsScope.GLOBAL,
                    '${credId}',
                    'Docker login for ${cloud.toUpperCase()} registry',
                    '${username}',
                    '''${password}'''
                )
                store.addCredentials(Domain.global(), cred)
                println("✅ Credential '${credId}' created.")
            }
        """

        sh """
            curl -s -X POST '${jenkinsUrl}/scriptText' \\
              --user \$JENKINS_USER:\$JENKINS_TOKEN \\
              --data-urlencode 'script=${script}'
        """
    }
}

return this
