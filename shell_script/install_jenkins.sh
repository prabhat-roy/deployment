#!/bin/bash
set -euo pipefail

ADMIN_USER="admin"
ADMIN_PASSWORD="admin"

echo "📦 Installing Jenkins..."

# Check if Jenkins is already installed
if command -v jenkins &> /dev/null; then
    echo "✅ Jenkins is already installed."
    sudo systemctl status jenkins --no-pager
    exit 0
fi

# Detect distribution and install Jenkins
if [ -f /etc/redhat-release ]; then
    echo "🔧 Detected RHEL/CentOS-based system"
    sudo yum install -y wget curl
    sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
    sudo yum install -y jenkins
    JENKINS_SERVICE="jenkins"
    JENKINS_DEFAULT="/etc/sysconfig/jenkins"

elif [ -f /etc/debian_version ]; then
    echo "🔧 Detected Debian/Ubuntu-based system"
    sudo apt update
    sudo apt install -y wget curl gnupg2
    sudo mkdir -p /etc/apt/keyrings
    sudo wget -q -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian/jenkins.io-2023.key
    echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt update
    sudo apt install -y jenkins
    JENKINS_SERVICE="jenkins"
    JENKINS_DEFAULT="/etc/default/jenkins"
else
    echo "❌ Unsupported OS. Exiting."
    exit 1
fi

echo "🛑 Stopping Jenkins to configure it..."
sudo systemctl stop "$JENKINS_SERVICE"

# Disable setup wizard
if grep -q 'JAVA_ARGS=' "$JENKINS_DEFAULT"; then
    sudo sed -i 's|JAVA_ARGS=.*|JAVA_ARGS="-Djenkins.install.runSetupWizard=false"|' "$JENKINS_DEFAULT"
else
    echo 'JAVA_ARGS="-Djenkins.install.runSetupWizard=false"' | sudo tee -a "$JENKINS_DEFAULT" > /dev/null
fi

echo "🔐 Configuring Jenkins admin user..."
sudo mkdir -p /var/lib/jenkins/init.groovy.d

sudo tee /var/lib/jenkins/init.groovy.d/basic-security.groovy > /dev/null <<EOF
#!groovy
import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()
println "--> Creating local Jenkins user"

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("${ADMIN_USER}", "${ADMIN_PASSWORD}")
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

instance.save()
EOF

sudo chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d
sudo chmod 644 /var/lib/jenkins/init.groovy.d/basic-security.groovy

echo "🔐 Creating Jenkins credentials: 'jenkins-cred'..."
sudo tee /var/lib/jenkins/init.groovy.d/jenkins-cred.groovy > /dev/null <<EOF
#!groovy
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import hudson.util.Secret
import jenkins.model.Jenkins

def creds_store = Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

def existingCreds = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
    com.cloudbees.plugins.credentials.common.StandardUsernamePasswordCredentials.class,
    Jenkins.instance,
    null,
    null
).find { it.id == "jenkins-cred" }

if (existingCreds == null) {
    println "--> Creating Jenkins credentials 'jenkins-cred'"
    def credentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        "jenkins-cred", "Auto-created by init script",
        "${ADMIN_USER}",
        "${ADMIN_PASSWORD}"
    )
    creds_store.addCredentials(Domain.global(), credentials)
} else {
    println "--> Jenkins credentials 'jenkins-cred' already exist"
}
EOF

sudo chown jenkins:jenkins /var/lib/jenkins/init.groovy.d/jenkins-cred.groovy
sudo chmod 644 /var/lib/jenkins/init.groovy.d/jenkins-cred.groovy

# Remove initial password if it exists
sudo rm -f /var/lib/jenkins/secrets/initialAdminPassword

echo "🔧 Adding 'jenkins' user to sudo/wheel group..."
if getent group sudo >/dev/null 2>&1; then
    sudo usermod -aG sudo jenkins
elif getent group wheel >/dev/null 2>&1; then
    sudo usermod -aG wheel jenkins
fi

echo "🔐 Configuring passwordless sudo for 'jenkins' user..."
echo "jenkins ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/jenkins-nopasswd
sudo chmod 440 /etc/sudoers.d/jenkins-nopasswd

echo "🕓 Setting timezone to Asia/Kolkata..."
sudo timedatectl set-timezone Asia/Kolkata

# ✅ Safe logging directory
echo "🗂️ Creating safe Jenkins log directory..."
sudo mkdir -p /var/log/jenkins-custom
sudo chown -R jenkins:jenkins /var/log/jenkins-custom
sudo chmod 755 /var/log/jenkins-custom

echo "🔄 Logging restart info..."
echo "Restart triggered at $(date)" | sudo tee -a /var/log/jenkins-custom/jenkins-restart.log > /dev/null

echo "🚀 Enabling and starting Jenkins service..."
sudo systemctl enable "$JENKINS_SERVICE"
sudo systemctl start "$JENKINS_SERVICE"

echo "✅ Jenkins installation and configuration completed!"
echo "👤 Admin username: $ADMIN_USER"
echo "🔐 Admin password: $ADMIN_PASSWORD"
echo "🔑 Jenkins credential ID: jenkins-cred (username/password)"

exit 0
