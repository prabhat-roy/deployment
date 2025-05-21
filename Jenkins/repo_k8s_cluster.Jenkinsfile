def call(action) {
pipeline {
    agent any

    parameters {
        choice(name: 'action', choices: ['create', 'destroy'], description: 'Create or Destroy repo & cluster')
    }

    stages {

        stage('Manage Repository - ${action}') {
            steps {
                script {
                    def cloudRepo = load 'groovy/cloud_repo.groovy'

                    if (params.action == 'create') {
                        echo "Creating repository..."
                        cloudRepo.createRepo()
                    } else if (params.action == 'destroy') {
                        echo "Removing repository..."
                        icloudRepo.removeRepo()
                    } else {
                        error "Invalid action parameter: ${params.action}"
                    }
                }
            }
        }

        stage('Manage Kubernetes Cluster - ${action}') {
            steps {
                script {
                    def kubernetesCluster = load 'groovy/kubernetes_cluster.groovy'

                    if (params.action == 'create') {
                        echo "Creating Kubernetes cluster..."
                        kubernetesCluster.createCluster()
                    } else if (params.action == 'destroy') {
                        echo "Removing Kubernetes cluster..."
                        kubernetesCluster.removeCluster()
                    } else {
                        error "Invalid action parameter: ${params.action}"
                    }
                }
            }
        }

        stage('Update Kubeconfig - ${action}') {
            steps {
                script {
                    def kubeconfigUpdate = load 'groovy/kubeconfig_update.groovy'

                    if (params.action == 'create') {
                        echo "Updating kubeconfig..."
                        kubeconfigUpdate.updateKubeconfig()
                    } else if (params.action == 'destroy') {
                        echo "Skipping kubeconfig update on destroy."
                    } else {
                        error "Invalid action parameter: ${params.action}"
                    }
                }
            }
        }

        stage('Repo Login - ${action}') {
            steps {
                script {
                    def repoLogin = load 'groovy/repo_login.groovy'

                    if (params.action == 'create') {
                        echo "Logging into repository..."
                        repoLogin.repoLogin()
                    } else if (params.action == 'destroy') {
                        echo "Skipping repo login on destroy."
                    } else {
                        error "Invalid action parameter: ${params.action}"
                    }
                }
            }
        }

        stage('Manage Karpenter Autoscaler - ${action}') {
            steps {
                script {
                    def karpenterAutoscaler = load 'groovy/karpenter_autoscaler.groovy'

                    if (params.action == 'create') {
                        echo "Installing Karpenter autoscaler..."
                        karpenterAutoscaler.install()
                    } else if (params.action == 'destroy') {
                        echo "Uninstalling Karpenter autoscaler..."
                        infraManager.uninstall()
                    } else {
                        error "Invalid action parameter: ${params.action}"
                    }
                }
            }
        }

        stage('Update and Archive Jenkins.env') {
            steps {
                script {
                    def infraManager = load 'groovy/infra_manager.groovy'

                    echo "Updating Jenkins.env file..."
                    infraManager.updateEnvFile()

                    echo "Archiving Jenkins.env..."
                    archiveArtifacts artifacts: 'Jenkins.env', onlyIfSuccessful: true
                    stash name: 'env-file', includes: 'Jenkins.env'
                }
            }
        }
    }
}
}
