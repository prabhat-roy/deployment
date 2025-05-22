#!/bin/bash
set -euo pipefail
# set -x  # Uncomment for debug trace

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

GRADLE_DIR="/opt/gradle"

get_latest_version() {
    curl -s https://services.gradle.org/versions/current | grep -oP '"version":\s*"\K[^"]+'
}

LATEST_VERSION=$(get_latest_version)
if [[ -z "$LATEST_VERSION" ]]; then
    echo "❌ Could not fetch the latest Gradle version."
    exit 1
fi

GRADLE_ZIP_URL="https://services.gradle.org/distributions/gradle-${LATEST_VERSION}-bin.zip"

check_installed() {
    if command -v gradle &>/dev/null; then
        echo "✅ Gradle already installed:"
        gradle -v
        return 0
    fi
    return 1
}

install_gradle() {
    echo "📥 Installing Gradle ${LATEST_VERSION}..."
    sudo mkdir -p "$GRADLE_DIR"
    if ! curl -fsSL "$GRADLE_ZIP_URL" -o /tmp/gradle.zip; then
        echo "❌ Failed to download Gradle zip from $GRADLE_ZIP_URL"
        exit 1
    fi
    if ! sudo unzip -q /tmp/gradle.zip -d "$GRADLE_DIR"; then
        echo "❌ Failed to unzip Gradle package"
        exit 1
    fi
    sudo ln -sf "$GRADLE_DIR/gradle-${LATEST_VERSION}/bin/gradle" /usr/bin/gradle
    gradle -v
}

add_gradle_to_jenkins() {
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
    <hudson.plugins.gradle.GradleInstallation>
      <name>Gradle-${LATEST_VERSION}</name>
      <home>${GRADLE_DIR}/gradle-${LATEST_VERSION}</home>
      <properties/>
    </hudson.plugins.gradle.GradleInstallation>
  </installations>
</jenkins>
EOF
)

    if ! curl -X POST "${JENKINS_URL}/descriptorByName/hudson.plugins.gradle.GradleInstallation/configure" \
         -H "Content-Type: text/xml" \
         -H "$CRUMB" \
         -u "${JENKINS_USER}:${JENKINS_PASS}" \
         --data-binary "${TOOL_PAYLOAD}"; then
        echo "❌ Failed to register Gradle tool in Jenkins."
        exit 1
    fi

    echo "✅ Gradle-${LATEST_VERSION} registered in Jenkins tools."
}

main() {
    if ! check_installed; then
        install_gradle
    fi
    add_gradle_to_jenkins
    echo "✅ Gradle setup complete."
}

main
