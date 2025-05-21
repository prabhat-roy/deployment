pipeline {
    agent any

    parameters {
        choice(name: 'PIPELINE', choices: ['plugin_install', 'tools_install', 'sonarqube_owasp_setup', 'repo_k8s_cluster', 'monitoring_stack', 'app_deploy'], description: 'Select pipeline to run')
        choice(name: 'ACTION', choices: ['create', 'destroy'], description: 'Choose action mode')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Run Selected Pipeline') {
            steps {
                script {
                    def pipelineFileMap = [
                        plugin_install       : 'jenkins/plugin_install.Jenkinsfile',
                        tools_install        : 'jenkins/tools_install.Jenkinsfile',
                        sonarqube_owasp_setup: 'jenkins/sonarqube_owasp_setup.Jenkinsfile',
                        repo_k8s_cluster     : 'jenkins/repo_k8s_cluster.Jenkinsfile',
                        monitoring_stack     : 'jenkins/monitoring_stack.Jenkinsfile',
                        app_deploy           : 'jenkins/app_deploy.Jenkinsfile'
                    ]

                    def selected = params.PIPELINE
                    if (!pipelineFileMap.containsKey(selected)) {
                        error "Unknown pipeline selected: ${selected}"
                    }

                    echo "Loading pipeline script: ${pipelineFileMap[selected]}"

                    // load returns the loaded script, so call it as a function if it defines one
                    def pipelineScript = load(pipelineFileMap[selected])

                    // If the pipeline script defines a call() method, call it to run the pipeline
                    pipelineScript.call(params.ACTION)
                }
            }
        }
    }
}
