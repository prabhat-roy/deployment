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
        // Create directory if not exists
        steps.sh "mkdir -p ${dcDir}"

        // Pull official Dependency-Check docker image
        steps.sh "docker pull owasp/dependency-check:latest"

        steps.echo "⏳ Running Dependency-Check container to download NVD data..."

        // Run container to download NVD data and cache locally
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

        // Remove cached data directory
        steps.sh "rm -rf ${dcDir}"

        // Remove docker image (ignore errors)
        steps.sh "docker rmi owasp/dependency-check:latest || true"

        steps.echo "✅ Cleanup completed."
    }
}

return new DependencyCheckInstaller(steps, env, params)
