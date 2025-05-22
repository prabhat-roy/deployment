#!/bin/bash
set -euo pipefail

# Default empty variables
JENKINS_URL=""
JENKINS_USER=""
JENKINS_PASS=""

# Parse arguments (supports both --arg val and --arg=val)
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --jenkins-url)
      JENKINS_URL="$2"
      shift 2
      ;;
    --jenkins-url=*)
      JENKINS_URL="${1#*=}"
      shift
      ;;
    --username)
      JENKINS_USER="$2"
      shift 2
      ;;
    --username=*)
      JENKINS_USER="${1#*=}"
      shift
      ;;
    --password)
      JENKINS_PASS="$2"
      shift 2
      ;;
    --password=*)
      JENKINS_PASS="${1#*=}"
      shift
      ;;
    *)
      echo "❌ Unknown parameter passed: $1"
      exit 1
      ;;
  esac
done

# Validate required arguments
: "${JENKINS_URL:?Missing --jenkins-url}"
: "${JENKINS_USER:?Missing --username}"
: "${JENKINS_PASS:?Missing --password}"

MAVEN_DIR="/opt/maven"

get_latest_version() {
    curl -s https://maven.apache.org/download.cgi |
        grep -oP 'apache-maven-\K[0-9]+\.[0-9]+\.[0-9]+' |
        head -1
}

LATEST_VERSION=$(get_latest_version)
if [[ -z "$LATEST_VERSION" ]]; then
    echo "❌ Could not fetch the latest Maven version."
    exit 1
fi

MAVEN_DOWNLOAD_URL="https://downloads.apache.org/maven/maven-3/${LATEST_VERSION}/binaries/apache-maven-${LATEST_VERSION}-bin.tar.gz"

check_installed() {
    if command -v mvn &>/dev/null; then
        echo "✅ Maven already installed:"
        mvn -v
        return 0
    fi
    return 1
}

install_maven() {
    echo "📥 Installing Maven ${LATEST_VERSION}..."

    echo "🔄 Cleaning old Maven installation if any..."
    sudo rm -rf "$MAVEN_DIR"
    sudo rm -f /usr/bin/mvn

    echo "🛠 Downloading Maven from $MAVEN_DOWNLOAD_URL"
    sudo mkdir -p "$MAVEN_DIR"
    curl -fsSL "$MAVEN_DOWNLOAD_URL" -o /tmp/maven.tar.gz
    sudo tar -xzf /tmp/maven.tar.gz -C "$MAVEN_DIR" --strip-components=1
    sudo ln -sf "$MAVEN_DIR/bin/mvn" /usr/bin/mvn

    echo "🔧 Verifying Maven executable:"
    ls -l /usr/bin/mvn
    file /usr/bin/mvn

    echo "🔍 Printing environment variables related to Java and Maven for debugging:"
    echo "JAVA_OPTS=$JAVA_OPTS"
    echo "MAVEN_OPTS=$MAVEN_OPTS"

    echo "🧪 Running mvn -v to verify installation:"
    mvn -v
}

add_maven_to_jenkins() {
    echo "🔐 Authenticating to Jenkins as ${JENKINS_USER}..."

    CRUMB=$(curl -s -u "${JENKINS_USER}:${JENKINS_PASS}" \
        "${JENKINS_URL}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")

    if [[ -z "$CRUMB" ]]; then
        echo "❌ Failed to get Jenkins crumb for CSRF protection."
        exit 1
    fi

    TOOL_PAYLOAD=$(cat <<EOF
<jenkins>
  <installations>
    <hudson.tasks.Maven_-MavenInstallation>
      <name>Maven-${LATEST_VERSION}</name>
      <home>${MAVEN_DIR}</home>
      <properties/>
    </hudson.tasks.Maven_-MavenInstallation>
  </installations>
</jenkins>
EOF
)

    curl -X POST "${JENKINS_URL}/descriptorByName/hudson.tasks.Maven\$MavenInstallation/configure" \
         -H "Content-Type: text/xml" \
         -H "$CRUMB" \
         -u "${JENKINS_USER}:${JENKINS_PASS}" \
         --data-binary "${TOOL_PAYLOAD}"

    echo "✅ Maven-${LATEST_VERSION} registered in Jenkins tools."
}

main() {
    if ! check_installed; then
        install_maven
    fi
    add_maven_to_jenkins
    echo "✅ Maven setup complete."
}

main
