#!/bin/bash
set -euo pipefail

echo "🚀 Starting Gradle installation script..."

GRADLE_DIR="/opt/gradle"
TEMP_ZIP="/tmp/gradle-latest.zip"
GRADLE_BIN_LINK="/usr/local/bin/gradle"

check_installed() {
    echo "🔍 Checking if Gradle is already installed..."
    if command -v gradle &>/dev/null; then
        echo "✅ Gradle is already installed:"
        gradle -v
        exit 0
    fi
    echo "📦 Gradle not found, proceeding with installation..."
}

get_latest_version() {
    curl -s https://services.gradle.org/versions/current | grep -oP '"version"\s*:\s*"\K[0-9.]+' | tr -d '\r\n[:space:]'
}

install_gradle() {
    local LATEST_VERSION
    LATEST_VERSION=$(get_latest_version)

    if [[ -z "$LATEST_VERSION" ]]; then
        echo "❌ Could not determine the latest Gradle version."
        exit 1
    fi

    echo "📥 Installing Gradle version: $LATEST_VERSION"
    local GRADLE_ZIP_URL="https://services.gradle.org/distributions/gradle-${LATEST_VERSION}-bin.zip"
    echo "🌐 Downloading from: $GRADLE_ZIP_URL"

    sudo mkdir -p "$GRADLE_DIR"
    curl -fsSL "$GRADLE_ZIP_URL" -o "$TEMP_ZIP" || {
        echo "❌ Failed to download Gradle."
        exit 1
    }

    echo "📦 Extracting Gradle ZIP..."
    sudo unzip -q "$TEMP_ZIP" -d "$GRADLE_DIR"

    local EXTRACTED_DIR="$GRADLE_DIR/gradle-${LATEST_VERSION}"

    if [[ ! -x "$EXTRACTED_DIR/bin/gradle" ]]; then
        echo "❌ Gradle binary not found in $EXTRACTED_DIR/bin/"
        exit 1
    fi

    echo "🔗 Creating symlink to /usr/local/bin/gradle..."
    sudo ln -sf "$EXTRACTED_DIR/bin/gradle" "$GRADLE_BIN_LINK"

    echo "✅ Gradle installed successfully!"
    gradle -v
}

main() {
    check_installed
    install_gradle
}

main "$@"
