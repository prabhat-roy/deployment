pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['create', 'destroy'], description: 'Choose create or destroy action')
    }

    stages {

        stage('Elastic Stack Setup') {
            steps {
                script {
                    def elasticInstaller = load 'groovy/elastic_stack.groovy'
                    if (params.ACTION == 'create') {
                        echo "🔧 Creating Elastic Stack..."
                        elasticInstaller.installElasticStack()
                    } else if (params.ACTION == 'destroy') {
                        echo "🗑️ Destroying Elastic Stack..."
                        elasticInstaller.deleteElasticStack()
                    } else {
                        error "Invalid ACTION parameter: ${params.ACTION}"
                    }
                }
            }
        }

        stage('Prometheus Stack Setup') {
            steps {
                script {
                    def prometheusInstaller = load 'groovy/prometheus_stack.groovy'
                    if (params.ACTION == 'create') {
                        echo "🔧 Creating Prometheus Stack..."
                        prometheusInstaller.installPrometheusStack()
                    } else if (params.ACTION == 'destroy') {
                        echo "🗑️ Destroying Prometheus Stack..."
                        prometheusInstaller.deletePrometheusStack()
                    } else {
                        error "Invalid ACTION parameter: ${params.ACTION}"
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                echo "Archiving Jenkins.env for next pipeline usage..."
                archiveArtifacts artifacts: 'Jenkins.env', onlyIfSuccessful: true
                stash name: 'env-file', includes: 'Jenkins.env'
            }
        }
    }
}
