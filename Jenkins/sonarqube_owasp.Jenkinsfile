def call(action) {
pipeline {
    agent any

    parameters {
        choice(name: 'action', choices: ['create', 'destroy'], description: 'Choose action: create or destroy')
    }

    stages {

        stage('Git Checkout') {
            steps {
                script {
                    checkout scm
                }
            }
        }

        stage('Manage SonarQube - ${action}') {
            steps {
                script {
                    def sonarqubeInstaller = load 'groovy/sonarqube.groovy'

                    if (params.action == 'create') {
                        sonarqubeInstaller.installSonarqube()
                    } else if (params.action == 'destroy') {
                        sonarqubeInstaller.cleanupSonarqube()
                    } else {
                        error "Invalid action: ${params.action}"
                    }
                }
            }
        }

        stage('Manage OWASP ZAP - ${action}') {
            steps {
                script {
                    def owaspInstaller = load 'groovy/owasp.groovy'

                    if (params.action == 'create') {
                        owaspInstaller.installOwasp()
                    } else if (params.action == 'destroy') {
                        owaspInstaller.cleanupOwasp()
                    } else {
                        error "Invalid action: ${params.action}"
                    }
                }
            }
        }
    }
}
}

