#!/bin/bash
# Update and upgrade the OS
set -e
install_semgrep() {
  echo "🔧 Installing Semgrep via virtual environment..."

  # Define installation directory
  local VENV_DIR="/opt/semgrep_venv"

  # Create virtual environment
  sudo python3 -m venv "$VENV_DIR"
  sudo "$VENV_DIR/bin/pip" install --upgrade pip
  sudo "$VENV_DIR/bin/pip" install semgrep

  # Symlink to global PATH
  sudo ln -sf "$VENV_DIR/bin/semgrep" /usr/local/bin/semgrep

  echo -n "✅ Semgrep version: "
  semgrep --version
}