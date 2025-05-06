#!/bin/bash
set -e

install_make() {
  echo "🔧 Installing latest GNU Make from source..."

  echo "📦 Installing build dependencies..."
  sudo apt-get update -y
  sudo apt-get install -y build-essential curl tar

  echo "🔍 Fetching latest GNU Make version from GNU FTP..."
  local MAKE_VERSION=$(curl -s https://ftp.gnu.org/gnu/make/ | grep -oP 'make-\K[0-9]+\.[0-9]+(\.[0-9]+)?(?=\.tar\.gz)' | sort -V | tail -n1)
  echo "📦 Latest Make version: ${MAKE_VERSION}"

  local TAR_FILE="make-${MAKE_VERSION}.tar.gz"
  local DOWNLOAD_URL="https://ftp.gnu.org/gnu/make/${TAR_FILE}"
  echo "⬇️ Downloading from: $DOWNLOAD_URL"
  curl -L "$DOWNLOAD_URL" -o "/tmp/$TAR_FILE"

  echo "📂 Extracting..."
  tar -xzf "/tmp/$TAR_FILE" -C /tmp

  echo "⚙️ Building GNU Make..."
  cd "/tmp/make-${MAKE_VERSION}"
  ./configure
  make -j"$(nproc)"

  echo "🚀 Installing GNU Make..."
  sudo make install

  echo -n "✅ Make version: "
  make --version | head -n1

  echo "🧹 Cleaning up..."
  rm -rf "/tmp/$TAR_FILE" "/tmp/make-${MAKE_VERSION}"
}
