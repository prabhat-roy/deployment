#!/bin/bash
set -euo pipefail

GRADLE_DIR="/opt/gradle"

check_installed() {
    if command -v gradle &>/dev/null; then
        echo "✅ Gradle is already installed:"
        gradle -v
        return 0
    fi
    return 1
}

get_latest_version() {
    curl -s https://services.gradle.org/versions/current | grep -oP '"version":\s*"\K[^"]+'
}

install_gradle() {
    LATEST_VERSION=$(get_latest_version)

    if [[ -z "$LATEST_VERSION" ]]; then
        echo "❌ Could not fetch the latest Gradle version."
        exit 1
    fi

    echo "📥 Installing Gradle ${LATEST_VERSION}..."

    GRADLE_ZIP_URL="https://services.gradle.org/distributions/gradle-${LATEST_VERSION}-bin.zip"

    sudo mkdir -p "$GRADLE_DIR"
    curl -fsSL "$GRADLE_ZIP_URL" -o /tmp/gradle.zip

    sudo unzip -q /tmp/gradle.zip -d "$GRADLE_DIR"
    sudo ln -sf "$GRADLE_DIR/gradle-${LATEST_VERSION}/bin/gradle" /usr/bin/gradle

    echo "✅ Gradle installation complete."
    gradle -v
}

main() {
    if ! check_installed; then
        install_gradle
    fi
}

main "$@"
