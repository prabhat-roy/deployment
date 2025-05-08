#!/bin/bash

# ============================================================================
# Jenkins Provisioning Script
# Automatically sources all scripts in install/ and executes functions.
# Logs output to console and /var/log/jenkins_install.log
# ============================================================================

# === Configurable ===
INSTALL_DIR="/tmp/install"
LOGFILE="/var/log/jenkins_install.log"

# === Enable DEBUG Mode if passed ===
DEBUG=${DEBUG:-false}
if [ "$DEBUG" = true ]; then
    set -euxo pipefail
else
    set -euo pipefail
fi

# === Logging Function ===
log() {
    local type="$1"; shift
    local message="$*"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    case "$type" in
        INFO) color="\e[34m";;
        WARN) color="\e[33m";;
        ERROR) color="\e[31m";;
        SUCCESS) color="\e[32m";;
        *) color="\e[0m";;
    esac

    echo -e "${color}[$timestamp] [$type] $message\e[0m"
}

# === Logging Setup: Save to log file as well as display ===
mkdir -p "$(dirname "$LOGFILE")"
touch "$LOGFILE"
exec > >(tee -a "$LOGFILE") 2>&1

log "INFO" "===== Jenkins Provisioning Started ====="

# === Source all .sh files from the install directory ===
log "INFO" "Sourcing function files from $INSTALL_DIR"
for script in "$INSTALL_DIR"/*.sh; do
    if [ -f "$script" ]; then
        log "INFO" "→ Loading: $(basename "$script")"
        source "$script"
    fi
done

# === Call your main functions here ===
# You can add more below as needed
log "INFO" "Starting core installations..."
update_upgrade_os
install_openjdk21
install_jenkins
log "SUCCESS" "===== Jenkins Provisioning Completed Successfully ====="
