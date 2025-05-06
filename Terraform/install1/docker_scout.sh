#!/bin/bash
set -e
#!/bin/bash
install_docker_scout() {
  echo "🔧 Installing Docker Scout CLI..."

  # Step 1: Get latest version from GitHub API
  LATEST_VERSION=$(curl -s https://api.github.com/repos/docker/scout-cli/releases/latest | grep '"tag_name":' | cut -d '"' -f 4)
  if [ -z "$LATEST_VERSION" ]; then
    echo "❌ Failed to fetch the latest Docker Scout release version."
    return 1
  fi
  echo "📦 Latest version: $LATEST_VERSION"

  # Remove 'v' prefix for the filename
  VERSION_NO_V="${LATEST_VERSION#v}"

  # Step 2: Build download URL with version in filename
  FILE_NAME="docker-scout_${VERSION_NO_V}_linux_amd64.tar.gz"
  DOWNLOAD_URL="https://github.com/docker/scout-cli/releases/download/${LATEST_VERSION}/${FILE_NAME}"
  echo "📥 Downloading from $DOWNLOAD_URL"

  # Step 3: Download
  curl -sSfL "$DOWNLOAD_URL" -o /tmp/docker-scout.tar.gz
  if [ $? -ne 0 ]; then
    echo "❌ Download failed. Check URL or network."
    return 1
  fi

  # Step 4: Extract
  echo "📂 Extracting archive..."
  tar -xvzf /tmp/docker-scout.tar.gz -C /tmp
  if [ ! -f /tmp/docker-scout ]; then
    echo "❌ docker-scout binary not found after extraction."
    return 1
  fi

  # Step 5: Move binary to /usr/local/bin
  echo "🚚 Moving binary to /usr/local/bin/"
  sudo mv /tmp/docker-scout /usr/local/bin/docker-scout
  sudo chmod +x /usr/local/bin/docker-scout

  # Step 6: Verify installation
  echo -n "✅ Docker Scout version: "
  if ! command -v docker-scout >/dev/null; then
    echo "❌ docker-scout not found in PATH."
    return 1
  fi
  docker-scout version

  # Step 7: Cleanup
  echo "🧹 Cleaning up..."
  rm -f /tmp/docker-scout.tar.gz
  find /tmp -name 'docker-scout*' -type f -delete

  echo "🎉 Docker Scout installed successfully!"
}