#!/bin/bash
set -euo pipefail

# Check if the script is running as root (necessary for creating cron jobs)
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

# Define installation directories
DC_DATA_DIR="/opt/dc-data"
DOCKER_IMAGE="owasp/dependency-check:latest"
NVD_UPDATE_CRON="0 0 * * * docker run --rm -v $DC_DATA_DIR:/usr/share/dependency-check/data $DOCKER_IMAGE --update-only"

# Create the directory for NVD data if it doesn't exist
echo "Creating directory for NVD data at $DC_DATA_DIR"
mkdir -p $DC_DATA_DIR

# Download the NVD database
echo "Downloading NVD database..."
docker run --rm -v $DC_DATA_DIR:/usr/share/dependency-check/data $DOCKER_IMAGE --update-only

# Setup cron job to update the NVD database daily at midnight
echo "Setting up cron job to update NVD database daily..."
(crontab -l 2>/dev/null; echo "$NVD_UPDATE_CRON") | crontab -

echo "OWASP Dependency-Check setup complete. The NVD database will be updated daily at midnight."
