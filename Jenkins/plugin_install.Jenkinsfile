pipeline {
    agent any  // Use any available agent (node) to run the pipeline

    stages {

        stage('Git Checkout') {
            steps {
                script {
                    // Checkout the code from the repository that triggered this pipeline
                    checkout scm
                }
            }
        }

        stage('Install Jenkins Plugins') {
            steps {
                script {
                    // Load the custom Groovy script from the specified path
                    // This script should define a method named InstallPlugin()
                    def jenkinsPlugin = load 'groovy/jenkins_plugin.groovy'
                    
                    // Call the method to install required Jenkins plugins
                    // Make sure this method handles plugin installation and restart logic safely
                    jenkinsPlugin.InstallPlugin()
                }
            }
        }

        // Optional: You can add a separate stage here for Jenkins restart using Jenkins API
        // But it’s safer to restart manually or conditionally in production pipelines
    }
}
