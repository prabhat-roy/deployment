pipeline {
    agent any

    // Parameters to choose which pipeline and action (create/destroy)
    parameters {
        choice(name: 'PIPELINE', choices: [
            'plugin_install', 
            'tools_install', 
            'sonarqube_owasp_setup', 
            'repo_k8s_cluster', 
            'monitoring_stack', 
            'app_deploy'
        ], description: 'Select pipeline to run')

        choice(name: 'ACTION', choices: ['create', 'destroy'], description: 'Choose action mode')
    }

    environment {
        ENV_FILE = 'jenkins.env'  // env file in root workspace
    }

    stages {
        stage('Load Existing Environment') {
            steps {
                script {
                    if (fileExists(env.ENV_FILE)) {
                        def props = readProperties file: env.ENV_FILE
                        props.each { k, v -> env."${k}" = v }
                        echo "Loaded environment variables from ${env.ENV_FILE}"
                    } else {
                        echo "No ${env.ENV_FILE} found. Starting fresh."
                    }
                }
            }
        }

        stage('Dispatch Selected Pipeline') {
            steps {
                script {
                    echo "Dispatching pipeline '${params.PIPELINE}' with action '${params.ACTION}'"

                    // Map of pipeline names to job names
                    def pipelineJobMap = [
                        plugin_install       : 'plugin_install_pipeline',
                        tools_install        : 'tools_install_pipeline',
                        sonarqube_owasp_setup: 'sonarqube_owasp_pipeline',
                        repo_k8s_cluster     : 'repo_k8s_cluster_pipeline',
                        monitoring_stack     : 'monitoring_stack_pipeline',
                        app_deploy           : 'app_deploy_pipeline'
                    ]

                    if (!pipelineJobMap.containsKey(params.PIPELINE)) {
                        error "Unknown pipeline selected: ${params.PIPELINE}"
                    }

                    def jobName = pipelineJobMap[params.PIPELINE]

                    // Trigger downstream job with parameters
                    build job: jobName,
                        parameters: [
                            string(name: 'ACTION', value: params.ACTION),
                            // Pass the env file as a parameter (optional, mainly for info)
                            string(name: 'ENV_FILE', value: env.ENV_FILE)
                        ],
                        wait: true
                }
            }
        }

        stage('Retrieve Updated Environment') {
            steps {
                script {
                    echo "Retrieving updated environment file '${env.ENV_FILE}' from downstream pipeline..."

                    // Copy artifact: updated jenkins.env from downstream job workspace root
                    step([
                        $class: 'CopyArtifact',
                        projectName: pipelineJobMap[params.PIPELINE],
                        filter: env.ENV_FILE,
                        flatten: true
                    ])

                    if (fileExists(env.ENV_FILE)) {
                        echo "Successfully updated ${env.ENV_FILE} collected."
                    } else {
                        echo "Warning: Updated ${env.ENV_FILE} NOT found after downstream pipeline."
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Dispatcher pipeline finished successfully."
        }
        failure {
            echo "Dispatcher pipeline failed."
        }
    }
}
