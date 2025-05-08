#!/bin/bash
set -e

install_dependency_check() {
  INSTALL_DIR="/opt/dependency-check"
  CACHE_DIR="$INSTALL_DIR/data"
  REPORT_DIR="$INSTALL_DIR/reports"
  BIN_LINK="/usr/local/bin/dependency-check"
  DOCKER_IMAGE="owasp/dependency-check:latest"

  echo "[*] Setting up directories..."
  mkdir -p "$CACHE_DIR" "$REPORT_DIR"

  if [ -f "$BIN_LINK" ]; then
    echo "[*] Dockerized Dependency-Check already configured."
    return
  fi

  echo "[*] Pulling latest OWASP Dependency-Check Docker image..."
  docker pull "$DOCKER_IMAGE" || { echo "[!] Failed to pull Docker image."; exit 1; }

  echo "[*] Creating executable wrapper at $BIN_LINK..."
  cat <<EOF > "$BIN_LINK"
#!/bin/bash
docker run --rm \
  -v "\$PWD:/src" \
  -v "$CACHE_DIR:/usr/share/dependency-check/data" \
  -v "$REPORT_DIR:/report" \
  "$DOCKER_IMAGE" "\$@"
EOF

  chmod +x "$BIN_LINK"

  echo "[*] Performing initial NVD update using Docker..."
  "$BIN_LINK" --updateonly || { echo "[!] Failed to update NVD."; exit 1; }

  echo "[✔] Dockerized OWASP Dependency-Check is ready."
  echo "    - NVD DB cache: $CACHE_DIR"
  echo "    - Reports: $REPORT_DIR"
  echo "    - Usage: Run 'dependency-check --scan /src --format HTML' etc."

  # Create Dockerfile with cron support
  echo "[*] Creating Dockerfile to include cron job for NVD updates..."
  cat <<EOF > Dockerfile
FROM $DOCKER_IMAGE

# Install cron and create the necessary directories
RUN apt-get update && apt-get install -y cron && \
    mkdir -p /etc/cron.d && \
    mkdir -p /usr/share/dependency-check/data && \
    touch /etc/cron.d/nvd-update

# Add the cron job to update NVD every Sunday at midnight
RUN echo "0 0 * * 7 /usr/local/bin/dependency-check --updateonly >> /var/log/cron.log 2>&1" > /etc/cron.d/nvd-update

# Give proper permissions to the cron file
RUN chmod 0644 /etc/cron.d/nvd-update && \
    crontab /etc/cron.d/nvd-update

# Start cron service and dependency-check
CMD cron && tail -f /var/log/cron.log
EOF

  echo "[*] Building the custom Docker image with cron job..."
  docker build -t custom-dependency-check:latest .

  echo "[✔] Cron job for NVD update set up inside the container. The cron job will run every Sunday at midnight."

  # Optionally, run the Docker container with the newly built image
  echo "[*] Running the custom Docker container..."
  docker run -d -v "$PWD:/src" -v "$CACHE_DIR:/usr/share/dependency-check/data" -v "$REPORT_DIR:/report" custom-dependency-check:latest

  echo "[✔] Docker container running with cron job for automatic NVD updates."
}
