import java.nio.file.Files
import java.nio.file.Paths

class DependencyCheckInstaller implements Serializable {
    def steps
    def env
    def params

    DependencyCheckInstaller(steps, env, params) {
        this.steps = steps
        this.env = env
        this.params = params
    }

    void installDependencyCheck() {
        steps.echo "🔧 Starting OWASP Dependency-Check installation..."

        def dcDir = "/opt/dependency-check"
        steps.sh "mkdir -p ${dcDir}"

        steps.sh "docker pull owasp/dependency-check:latest"

        steps.echo "⏳ Running Dependency-Check container to download NVD data..."

        steps.sh """
            docker run --rm \\
                -v ${dcDir}:/usr/share/dependency-check/data \\
                owasp/dependency-check:latest \\
                --updateonly
        """

        steps.echo "✅ OWASP Dependency-Check installation and NVD database caching completed."
    }

    void cleanupDependencyCheck() {
        def dcDir = "/opt/dependency-check"

        steps.echo "🧹 Cleaning up OWASP Dependency-Check data..."

        steps.sh "rm -rf ${dcDir}"

        steps.sh "docker rmi owasp/dependency-check:latest || true"

        steps.echo "✅ Cleanup completed."
    }
}

// Return an instance to the pipeline script
return new DependencyCheckInstaller(steps, env, params)
