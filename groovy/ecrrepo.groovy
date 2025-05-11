def createEcrRepos() {
    echo "🔧 Creating ECR Repositories from .env"

    sh '''
        chmod +x generate-ecr.sh
        ./generate-ecr.sh
    '''
}

return this
