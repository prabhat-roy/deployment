def call() {
    pipeline {
        agent any

        stages {
            stage('Git Checkout') {
                steps {
                    script {
                        checkout scm
                    }
                }
            }

            stage('Install Jenkins Plugins') {
                steps {
                    script {
                        def jenkinsPlugin = load 'groovy/jenkins_plugin.groovy'
                        jenkinsPlugin.InstallPlugin()
                    }
                }
            }

            // Optional restart logic here if needed
        }
    }
}
