#!/bin/bash
set -euxo pipefail
install_docker() {
# Install Docker
set -e
echo "🔧 Installing dependencies..."
sudo apt install -y ca-certificates lsb-release apt-transport-https software-properties-common
echo "🔑 Adding Docker’s official GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "➕ Setting up Docker stable repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "📥 Installing Docker Engine, CLI, Compose, and containerd..."
sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
echo "👥 Adding user '$USER' to the 'docker' group..."
sudo usermod -aG docker $USER

echo "🔁 Enabling and starting Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

echo "🔍 Verifying Docker and Compose installation..."
docker --version
docker compose version

echo "✅ Docker Engine + Compose v2 installed successfully!"
}
install_kubernetes() {
#  ### Install kubectl
  echo "🔧 Installing kubectl..."
  sudo curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

  ### Install Helm
  echo "🔧 Installing Helm..."
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 get_helm.sh
  ./get_helm.sh
  ### Install Kustomize
  echo "🔧 Installing Kustomize..."
  curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
}
install_jenkins() {
  echo "🔧 Installing Jenkins..."

  # Add the Jenkins repository key to the system
  wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -

  # Add the Jenkins repository to the system
  echo deb http://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list

  # Update the package index
  sudo apt update -y

  # Install Jenkins
  sudo apt install jenkins -y

  # Start Jenkins service
  sudo systemctl start jenkins

  # Enable Jenkins to start on boot
  sudo systemctl enable jenkins
  sudo usermod -aG sudo jenkins
  sudo usermod -aG docker jenkins
  # Print Jenkins version
  echo -n "✅ Jenkins version: "
  jenkins --version
}



install_trivy() {
  echo "🔧 Installing Trivy vulnerability scanner..."

  # Install required dependencies
  sudo apt-get update -y
  # Add Trivy APT repository
  wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
  echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
  # Install Trivy
  sudo apt-get update -y
  sudo apt-get install -y trivy

  # Verify installation
  echo -n "✅ Trivy version: "
  trivy --version
}
install_grype() {
  echo "🔧 Installing Grype (vulnerability scanner)..."
  curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sudo bash -s -- -b /usr/local/bin
  echo -n "✅ Grype version: "
  grype version
}
install_syft() {
  echo "🔧 Installing Syft (SBOM generator)..."
  curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sudo bash -s -- -b /usr/local/bin
  echo -n "✅ Syft version: "
  syft version
}
install_docker_scout() {
  echo "🔧 Installing Docker Scout CLI plugin..."

  # Fetch the latest release version
  DOCKER_SCOUT_VERSION=$(curl -s https://api.github.com/repos/docker/scout-cli/releases/latest | grep tag_name | cut -d '"' -f 4)

  # Download archive
  DOWNLOAD_URL="https://github.com/docker/scout-cli/releases/download/${DOCKER_SCOUT_VERSION}/docker-scout-linux-amd64.tar.gz"
  echo "📥 Downloading from $DOWNLOAD_URL"

  curl -fL "$DOWNLOAD_URL" -o /tmp/scout.tar.gz
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to download Docker Scout from GitHub."
    exit 1
  fi

  # Check the file type
  if ! file /tmp/scout.tar.gz | grep -q 'gzip compressed data'; then
    echo "❌ Downloaded file is not a valid gzip archive."
    cat /tmp/scout.tar.gz
    exit 1
  fi

  # Extract
  echo "📦 Extracting..."
  tar -xzf /tmp/scout.tar.gz -C /tmp || {
    echo "❌ Failed to extract Docker Scout archive."
    exit 1
  }

  # Move binary if it exists
  if [[ -f /tmp/docker-scout ]]; then
    sudo mv /tmp/docker-scout /usr/local/bin/docker-scout
    sudo chmod +x /usr/local/bin/docker-scout
    rm /tmp/scout.tar.gz
    echo -n "✅ Docker Scout version: "
    docker-scout version
  else
    echo "❌ docker-scout binary not found in archive."
    ls -la /tmp/
    exit 1
  fi
}
install_cosign() {
  echo "🔐 Installing Cosign (container signing tool)..."

  # Detect latest version
  COSIGN_VERSION=$(curl -s https://api.github.com/repos/sigstore/cosign/releases/latest | grep '"tag_name":' | cut -d '"' -f 4)
  echo "📦 Latest Cosign version: $COSIGN_VERSION"

  if [[ -z "$COSIGN_VERSION" ]]; then
    echo "❌ Failed to fetch latest Cosign version from GitHub."
    return 1
  fi

  # Construct download URL
  COSIGN_URL="https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-amd64"
  echo "📥 Downloading from: $COSIGN_URL"

  # Download and install
  curl -fL "$COSIGN_URL" -o /tmp/cosign || {
    echo "❌ Failed to download Cosign binary."
    return 1
  }

  chmod +x /tmp/cosign
  sudo mv /tmp/cosign /usr/local/bin/cosign

  # Verify installation
  if command -v cosign >/dev/null 2>&1; then
    echo -n "✅ Cosign successfully installed. Version: "
    cosign version
  else
    echo "❌ Cosign installation failed."
    return 1
  fi
}
install_snyk() {
  echo "🔧 Installing Snyk CLI using npm..."

  # Install Snyk globally using npm
  sudo npm install -g snyk

  # Verify installation
  if command -v snyk >/dev/null 2>&1; then
    echo -n "✅ Snyk successfully installed. Version: "
    snyk --version
  else
    echo "❌ Snyk installation failed."
    return 1
  fi
}
install_spectral() {
  echo "🔧 Installing Spectral CLI using npm..."

  # Check if Node.js and npm are installed
  if ! command -v npm &>/dev/null; then
    echo "❌ npm is not installed. Please install Node.js and npm first."
    return 1
  fi

  # Install Spectral globally
  sudo npm install -g @stoplight/spectral

  # Verify installation
  if command -v spectral &>/dev/null; then
    echo -n "✅ Spectral installed successfully. Version: "
    spectral --version
  else
    echo "❌ Spectral installation failed."
    return 1
  fi
}

install_semgrep() {
  echo "🔧 Installing Semgrep via virtual environment..."

  # Define installation directory
  local VENV_DIR="/opt/semgrep_venv"

  # Install required dependencies
  sudo apt-get update -y
  sudo apt-get install -y python3 python3-venv python3-pip

  # Create virtual environment
  sudo python3 -m venv "$VENV_DIR"
  sudo "$VENV_DIR/bin/pip" install --upgrade pip
  sudo "$VENV_DIR/bin/pip" install semgrep

  # Symlink to global PATH
  sudo ln -sf "$VENV_DIR/bin/semgrep" /usr/local/bin/semgrep

  echo -n "✅ Semgrep version: "
  semgrep --version
}

install_calicoctl() {
  echo "🔧 Installing calicoctl on Ubuntu..."

  # Determine the latest version
  echo "📦 Fetching latest calicoctl version..."
  LATEST_VERSION=$(curl -s https://api.github.com/repos/projectcalico/calico/releases/latest | grep tag_name | cut -d '"' -f 4)

  if [[ -z "$LATEST_VERSION" ]]; then
    echo "❌ Failed to fetch the latest version of calicoctl."
    return 1
  fi

  echo "⬇️  Downloading calicoctl $LATEST_VERSION..."
  curl -L -o /usr/local/bin/calicoctl "https://github.com/projectcalico/calico/releases/download/${LATEST_VERSION}/calicoctl-linux-amd64"

  # Make it executable
  chmod +x /usr/local/bin/calicoctl

  # Verify installation
  if command -v calicoctl &>/dev/null; then
    echo -n "✅ calicoctl installed successfully. Version: "
    calicoctl version
  else
    echo "❌ calicoctl installation failed."
    return 1
  fi
}
install_newrelic_cli() {
  echo "🔧 Installing New Relic CLI..."

  # Get latest version from GitHub
  local VERSION=$(curl -s https://api.github.com/repos/newrelic/newrelic-cli/releases/latest | grep tag_name | cut -d '"' -f 4)
  echo "📦 Latest New Relic CLI version: $VERSION"

  # Download and install the correct binary (Linux AMD64)
  curl -sL "https://github.com/newrelic/newrelic-cli/releases/download/${VERSION}/newrelic-cli_${VERSION:1}_Linux_x86_64.tar.gz" -o /tmp/newrelic-cli.tar.gz

  echo "📦 Extracting New Relic CLI..."
  mkdir -p /tmp/newrelic-cli
  tar -xzf /tmp/newrelic-cli.tar.gz -C /tmp/newrelic-cli

  echo "🚀 Moving binary to /usr/local/bin..."
  sudo mv /tmp/newrelic-cli/newrelic /usr/local/bin/

  echo -n "✅ New Relic CLI version: "
  newrelic version
}
install_checkov() {
  echo "🔧 Installing Checkov in isolated virtual environment..."

  # Ensure required packages are installed
  sudo apt-get update -qq
  sudo apt-get install -y python3 python3-venv python3-pip

  # Create a virtual environment specifically for Checkov
  CHECKOV_VENV_DIR="/opt/checkov-venv"
  sudo python3 -m venv "$CHECKOV_VENV_DIR"
  sudo "$CHECKOV_VENV_DIR/bin/pip" install --upgrade pip setuptools

  echo "📦 Installing Checkov..."
  sudo "$CHECKOV_VENV_DIR/bin/pip" install checkov

  # Symlink to make Checkov globally available
  sudo ln -sf "$CHECKOV_VENV_DIR/bin/checkov" /usr/local/bin/checkov

  echo -n "✅ Checkov version: "
  checkov --version
}
    echo "🔧 Installing Clair and Clairctl on Ubuntu..."

    # Step 1: Install required dependencies
    sudo apt update
    sudo apt install -y golang-go postgresql wget curl jq ufw

    # Step 2: Install PostgreSQL and start service
    echo "🔧 Setting up PostgreSQL for Clair..."
    sudo systemctl start postgresql
    sudo systemctl enable postgresql

    # Step 3: Create PostgreSQL database and user for Clair
    sudo -u postgres psql -c "CREATE DATABASE clair;"
    sudo -u postgres psql -c "CREATE USER clair WITH PASSWORD 'clair';"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE clair TO clair;"

    # Step 4: Fetch the latest version of Clair from GitHub
    echo "🔧 Fetching the latest Clair release..."
    LATEST_CLAIR_RELEASE=$(curl -s https://api.github.com/repos/quay/clair/releases/latest | jq -r '.tag_name')

    if [ "$LATEST_CLAIR_RELEASE" == "null" ]; then
        echo "❌ Failed to fetch the latest Clair release version."
        exit 1
    fi

    CLAIR_BINARY="clair-linux-amd64-${LATEST_CLAIR_RELEASE#v}"

    # Step 5: Download Clair
    echo "🔧 Downloading Clair version ${LATEST_CLAIR_RELEASE}..."
    wget "https://github.com/quay/clair/releases/download/${LATEST_CLAIR_RELEASE}/${CLAIR_BINARY}.tar.gz" -O /tmp/clair.tar.gz

    # Step 6: Extract and install Clair
    echo "🔧 Extracting Clair binary..."
    tar -xvzf /tmp/clair.tar.gz -C /tmp
    sudo mv /tmp/clair /usr/local/bin/clair

    # Clean up temporary files
    rm /tmp/clair.tar.gz

    # Step 7: Configure Clair (download default config)
    echo "🔧 Configuring Clair..."
    mkdir -p ~/clair-config
    curl -sL https://raw.githubusercontent.com/quay/clair/main/clair-config.yaml -o ~/clair-config/config.yaml

    # Step 8: Install Clairctl
    echo "🔧 Installing Clairctl..."
    CLAIRCTL_RELEASE=$(curl -s https://api.github.com/repos/quay/clairctl/releases/latest | jq -r '.tag_name')
    CLAIRCTL_BINARY="clairctl-linux-amd64-${CLAIRCTL_RELEASE#v}"
    wget "https://github.com/quay/clairctl/releases/download/${CLAIRCTL_RELEASE}/${CLAIRCTL_BINARY}.tar.gz" -O /tmp/clairctl.tar.gz

    # Extract and install Clairctl
    tar -xvzf /tmp/clairctl.tar.gz -C /tmp
    sudo mv /tmp/clairctl /usr/local/bin/clairctl
    rm /tmp/clairctl.tar.gz

    # Step 9: Create systemd service for Clair
    echo "🔧 Creating systemd service for Clair..."
    sudo tee /etc/systemd/system/clair.service > /dev/null <<EOL
[Unit]
Description=Clair Vulnerability Scanner
After=network.target

[Service]
ExecStart=/usr/local/bin/clair -config /home/ubuntu/clair-config/config.yaml
WorkingDirectory=/home/ubuntu
Restart=on-failure
User=ubuntu
Group=ubuntu

[Install]
WantedBy=multi-user.target
EOL

    # Step 10: Reload systemd, start Clair service, and enable on boot
    echo "🔧 Starting Clair service..."
    sudo systemctl daemon-reload
    sudo systemctl start clair
    sudo systemctl enable clair

    # Step 11: Configure UFW firewall rules for Clair
    echo "🛡️ Configuring UFW firewall rules for Clair..."
    sudo ufw --force enable
    sudo ufw allow OpenSSH
    sudo ufw allow 6060/tcp  # Clair API Port
    sudo ufw allow 6061/tcp  # Clairctl gRPC Port
    sudo ufw reload

    # Step 12: Display firewall status
    echo "🔍 UFW status:"
    sudo ufw status verbose

    # Step 13: Verify Clair status
    echo "🔧 Verifying Clair status..."
    sudo systemctl status clair

install_falco() {
    echo "🔧 Installing Falco on Ubuntu..."

    # Step 1: Add the Falco repository
    echo "📝 Adding Falco APT repository..."
    curl -s https://s3.us-west-2.amazonaws.com/download.draios.com/stable/deb/draios-stable.asc | sudo apt-key add -
    sudo curl -s -o /etc/apt/sources.list.d/draios.list https://download.draios.com/stable/deb/draios.list

    # Step 2: Update package list
    sudo apt update

    # Step 3: Install Falco
    echo "📝 Installing Falco..."
    sudo apt install -y falco

    # Step 4: Enable and start Falco service
    echo "🔧 Enabling and starting Falco service..."
    sudo systemctl enable falco
    sudo systemctl start falco

    # Step 5: Verify installation
    echo "🔧 Verifying Falco installation..."
    sudo systemctl status falco

    # Step 6: Clean up (optional)
    # No clean-up needed for package installation

    echo "✅ Falco installation and setup completed successfully!"
}
