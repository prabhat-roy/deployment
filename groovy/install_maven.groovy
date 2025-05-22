class MavenInstaller implements Serializable {

    def steps

    MavenInstaller(steps) {
        this.steps = steps
    }

    def installMaven() {
        steps.sh '''
            #!/bin/bash
            set -e
            echo "Executing install_maven.sh script..."
            chmod +x ./scripts/install_maven.sh
            ./scripts/install_maven.sh
        '''
    }
}

return new MavenInstaller(this)