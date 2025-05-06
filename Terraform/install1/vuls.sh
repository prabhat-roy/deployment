#!/bin/bash
set -e

install_vuls() {
    # Define Docker images (excluding vulsrepo)
    VULS_IMAGES=(
        "vuls/go-cve-dictionary"
        "vuls/goval-dictionary"
        "vuls/gost"
        "vuls/go-exploitdb"
        "vuls/go-msfdb"
        "vuls/go-kev"
        "vuls/go-cti"
        "vuls/vuls"
    )

    VULS_CONFIG_DIR=~/vuls/config
    VULS_LOG_DIR=~/vuls/log
    VULS_RESULTS_DIR=~/vuls/results

    echo "📁 Creating necessary directories for Vuls..."
    mkdir -p "$VULS_CONFIG_DIR" "$VULS_LOG_DIR" "$VULS_RESULTS_DIR"

    echo "📄 Generating default config.toml..."
    cat <<EOF > "$VULS_CONFIG_DIR/config.toml"
[servers]
[servers.localhost]
host = "localhost"
port = "local"
scanMode = ["fast"]
EOF

    echo "⬇️ Pulling Docker images..."
    for image in "${VULS_IMAGES[@]}"; do
        echo "⬇️ Pulling $image"
        sudo docker pull "$image" || { echo "❌ Failed to pull $image"; exit 1; }
    done

    echo "🧹 Cleaning up existing containers..."
    for name in go-cve-dictionary goval-dictionary gost go-exploitdb go-msfdb go-kev go-cti vuls; do
        sudo docker rm -f "$name" >/dev/null 2>&1 || true
    done

    echo "🚀 Running Docker containers in background..."
    sudo docker run -d --name go-cve-dictionary -v "$VULS_CONFIG_DIR:/config" -v "$VULS_LOG_DIR:/log" vuls/go-cve-dictionary tail -f /dev/null
    sudo docker run -d --name goval-dictionary -v "$VULS_CONFIG_DIR:/config" -v "$VULS_LOG_DIR:/log" vuls/goval-dictionary tail -f /dev/null
    sudo docker run -d --name gost -v "$VULS_CONFIG_DIR:/config" -v "$VULS_LOG_DIR:/log" vuls/gost tail -f /dev/null
    sudo docker run -d --name go-exploitdb -v "$VULS_CONFIG_DIR:/config" -v "$VULS_LOG_DIR:/log" vuls/go-exploitdb tail -f /dev/null
    sudo docker run -d --name go-msfdb -v "$VULS_CONFIG_DIR:/config" -v "$VULS_LOG_DIR:/log" vuls/go-msfdb tail -f /dev/null
    sudo docker run -d --name go-kev -v "$VULS_CONFIG_DIR:/config" -v "$VULS_LOG_DIR:/log" vuls/go-kev tail -f /dev/null
    sudo docker run -d --name go-cti -v "$VULS_CONFIG_DIR:/config" -v "$VULS_LOG_DIR:/log" vuls/go-cti tail -f /dev/null
    sudo docker run -d --name vuls -v "$VULS_CONFIG_DIR:/config" -v "$VULS_LOG_DIR:/log" -v "$VULS_RESULTS_DIR:/results" vuls/vuls tail -f /dev/null

    echo "📅 Setting up cron jobs for Vuls database updates..."
    CRON_FILE="/etc/cron.d/vuls-db-update"

    sudo tee "$CRON_FILE" > /dev/null <<EOF
# Update CVEs from NVD and RedHat every 6 hours
0 */6 * * * root docker exec go-cve-dictionary go-cve-dictionary fetch nvd
30 */6 * * * root docker exec go-cve-dictionary go-cve-dictionary fetch redhat

# Update Exploit DB every 6 hours
15 */6 * * * root docker exec go-exploitdb go-exploitdb fetch exploit-db

# Update MSF DB every 6 hours
45 */6 * * * root docker exec go-msfdb go-msfdb fetch

# Update Goval Dictionary (RedHat, Debian, Ubuntu) every 6 hours
5 */6 * * * root docker exec goval-dictionary goval-dictionary fetch redhat
10 */6 * * * root docker exec goval-dictionary goval-dictionary fetch debian
15 */6 * * * root docker exec goval-dictionary goval-dictionary fetch ubuntu

# Update KEV
20 */6 * * * root docker exec go-kev go-kev fetch

# Update CTI
25 */6 * * * root docker exec go-cti go-cti fetch

# Update GOST (GitHub Security Advisory)
50 */6 * * * root docker exec gost gost fetch github
EOF

    sudo chmod 644 "$CRON_FILE"
    sudo systemctl restart cron

    sleep 10

    echo "📦 Listing running Vuls containers..."
    sudo docker ps --filter "name=go-"
    echo "✅ Vuls setup is complete and containers are running."
}
