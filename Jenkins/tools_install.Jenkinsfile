def call() {
pipeline {
    agent any

    stages {

        // === GIT & DETECTION ===

        stage('Git Checkout') {
            steps {
                script {
                    // Checkout code from the configured SCM
                    checkout scm
                }
            }
        }

        stage('Detect Cloud Provider') {
            steps {
                script {
                    // Load and execute the cloud detection utility
                    def cloudScript = load 'groovy/detect_cloud.groovy'
                    cloudScript.detectAndSaveCloudProvider()
                }
            }
        }

        stage('Install docker') {
            steps {
                script {
                    def dockerInstaller = load 'groovy/install_docker.groovy'
                    dockerInstaller.installDocker()
                }
            }
        }

        stage('Detect Microservices') {
            steps {
                script {
                    def envWriter = load 'groovy/env_writer.groovy'

                    // Detect all folders in src/
                    def services = sh(
                        script: "find src -mindepth 1 -maxdepth 1 -type d -exec basename {} \\; | sort | tr '\\n' ',' | sed 's/,\$//'",
                        returnStdout: true
                    ).trim()

                    // Detect only those with Dockerfile
                    def dockerServices = sh(
                        script: "find src -mindepth 1 -maxdepth 1 -type d -exec sh -c '[ -f \"{}/Dockerfile\" ] && basename {}' \\; | sort | tr '\\n' ',' | sed 's/,\$//'",
                        returnStdout: true
                    ).trim()

                    echo "📦 All services: ${services}"
                    echo "🐳 Dockerized services: ${dockerServices}"

                    // Write both to the env file
                    envWriter.writeEnvVars([
                        'SERVICES': services,
                        'DOCKER_SERVICES': dockerServices
                    ])
                }
            }
        }

        stage('Inject Environment Variables') {
            steps {
                script {
                    // Load variables from Jenkins.env and inject them into pipeline environment
                    def envLoader = load 'groovy/env_loader.groovy'
                    def envVars = envLoader.loadEnvVars("Jenkins.env")
                    envVars.each { key, val ->
                        env."${key}" = val
                        echo "Injected: ${key}=${val}"
                    }
                }
            }
        }

        // === SYSTEM UTILITIES INSTALLATION ===

        stage('Install Curl') {
            steps {
                script {
                    // Install curl command-line tool
                    def curlInstaller = load 'groovy/curl.groovy'
                    curlInstaller.installCurl()
                }
            }
        }

        stage('Install Wget') {
            steps {
                script {
                    // Install wget command-line tool
                    def wgetInstaller = load 'groovy/wget.groovy'
                    wgetInstaller.installWget()
                }
            }
        }

        stage('Install Unzip') {
            steps {
                script {
                    // Install unzip utility
                    def unzipInstaller = load 'groovy/unzip.groovy'
                    unzipInstaller.installUnzip()
                }
            }
        }

        stage('Install GnuPG') {
            steps {
                script {
                    // Install GnuPG (GNU Privacy Guard) for secure communication
                    def gnupgInstaller = load 'groovy/gnupg.groovy'
                    gnupgInstaller.installGnupg()
                }
            }
        }

        stage('Install Make') {
            steps {
                script {
                    // Install GNU Make tool
                    def makeInstaller = load 'groovy/make.groovy'
                    makeInstaller.installMake()
                }
            }
        }

        // === LANGUAGE RUNTIME ENVIRONMENTS ===

        stage('Install Python') {
            steps {
                script {
                    // Install Python runtime
                    def pythonInstaller = load 'groovy/python.groovy'
                    pythonInstaller.installPython()
                }
            }
        }

        stage('Install Node.js') {
            steps {
                script {
                    // Install Node.js runtime
                    def nodejsInstaller = load 'groovy/nodejs.groovy'
                    nodejsInstaller.installNodejs()
                }
            }
        }

        // === INFRASTRUCTURE & CLI TOOLS ===

        stage('Install Cloud CLI Tool') {
            steps {
                script {
                    // Install AWS CLI / Azure CLI / GCP CLI depending on cloud provider
                    def cliInstaller = load 'groovy/cloud_cli.groovy'
                    cliInstaller.installCloudCLI()
                }
            }
        }

        stage('Install Terraform') {
            steps {
                script {
                    // Install Terraform CLI
                    def terraformInstaller = load 'groovy/terraform.groovy'
                    terraformInstaller.installTerraform()
                }
            }
        }

        stage('Install Kubernetes CLI Tools') {
            steps {
                script {
                    // Install kubectl, helm, kustomize, etc.
                    def kubernetesInstaller = load 'groovy/install_kubernetes.groovy'
                    kubernetesInstaller.installKubernetes()
                }
            }
        }

        // === VERIFY TOOL VERSIONS ===

        stage('Verify Tool Versions') {
            steps {
                script {
                    sh '''
                        echo "🔧 Installed Versions:"
                        echo "Docker: $(docker --version || echo not found)"
                        echo "Docker Compose: $(docker-compose --version || echo not found)"
                        echo "Python: $(python3 --version || echo not found)"
                        echo "Node.js: $(node --version || echo not found)"
                        echo "Terraform: $(terraform -version | head -n 1 || echo not found)"
                        echo "kubectl: $(kubectl version --client=true --short || echo not found)"
                        echo "Helm: $(helm version --short || echo not found)"
                        echo "Kustomize: $(kustomize version || echo not found)"
                        echo "Vault: $(vault --version || echo not found)"
                        echo "jq: $(jq --version || echo not found)"
                        echo "dig: $(dig +short google.com || echo not found)"
                        echo "nc: $(nc -h 2>&1 | head -n 1 || echo not found)"
                    '''
                }
            }
        }

        // === ENVIRONMENT FILE HANDOFF ===

        stage('Archive Jenkins.env') {
            steps {
                script {
                    // Archive Jenkins.env for visibility and stash for next pipeline usage
                    archiveArtifacts artifacts: 'Jenkins.env', onlyIfSuccessful: true
                    stash name: 'env-file', includes: 'Jenkins.env'
                }
            }
        }

        // === CLEANUP ===

        stage('Clean Workspace') {
            steps {
                script {
                    // Remove all workspace files for a clean start in next run
                    deleteDir()
                    echo "Workspace deleted."
                }
            }
        }

        stage('Graceful Jenkins Restart') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                echo "⚙️ Scheduling Jenkins restart via systemctl..."
                sh '''
                    nohup bash -c "sleep 10 && sudo systemctl restart jenkins" > /var/log/jenkins-restart.log 2>&1 &
                    echo "✅ Jenkins will restart gracefully in 10 seconds (in background)."
                '''
            }
        }
    }
    }
}
