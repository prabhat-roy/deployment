#!/bin/bash
set -euo pipefail

GRADLE_DIR="/opt/gradle"
GRADLE_BIN_LINK="/usr/local/bin/gradle"
TEMP_ZIP="/tmp/gradle.zip"

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
    echo "📦 Downloading Gradle from: $GRADLE_ZIP_URL"
    curl -fsSL "$GRADLE_ZIP_URL" -o "$TEMP_ZIP"

    # Extract the archive
    sudo unzip -q -d "$GRADLE_DIR" "$TEMP_ZIP"

    # Detect extracted directory name
    EXTRACTED_DIR=$(find "$GRADLE_DIR" -maxdepth 1 -type d -name "gradle-${LATEST_VERSION}" | head -n 1)

    if [[ -z "$EXTRACTED_DIR" || ! -f "$EXTRACTED_DIR/bin/gradle" ]]; then
        echo "❌ Gradle binary not found after extraction."
        exit 1
    fi

    # Symlink
    sudo ln -sf "$EXTRACTED_DIR/bin/gradle" "$GRADLE_BIN_LINK"

    echo "✅ Gradle installation complete."
    gradle -v
}

main() {
    if ! check_installed; then
        install_gradle
    fi
}

main "$@"
