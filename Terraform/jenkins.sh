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
install_wget
install_gnupg
install_curl
install_openjdk21
install_jenkins
# install_terraform
# install_kubernetes
# install_trivy
# install_grype
# install_syft
# install_docker_scout
# install_cosign
# install_nodejs
# install_snyk
# install_spectral
# install_semgrep
# install_jenkins
# install_calicoctl

# install_python
# install_newrelic_cli
# install_checkov
# install_clair
# install_falco
# install_tetragon
# install_zaproxy
# install_puppet
# install_stackstorm

# install_dependency_check
# install_codacy_cli
# install_ansible
# install_make
# install_git
# install_go
# install_gcp_cli
# install_azure_cli
# install_aws_cli
# install_unzip
# install_docker
# install_sonarqube

log "SUCCESS" "===== Jenkins Provisioning Completed Successfully ====="
