#!/bin/bash
set -e

jenkins() {
    ADMIN_USER="admin"
    ADMIN_PASSWORD="admin"

    echo "📦 Installing Jenkins..."

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

        sudo apt-get update
        sudo apt-get install -y wget curl gnupg2

        sudo mkdir -p /etc/apt/keyrings
        sudo wget -q -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian/jenkins.io-2023.key
        echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y jenkins

        JENKINS_SERVICE="jenkins"
        JENKINS_DEFAULT="/etc/default/jenkins"

    else
        echo "❌ Unsupported OS. Exiting."
        exit 1
    fi

    # === Disable Setup Wizard ===
    echo 'JAVA_ARGS="-Djenkins.install.runSetupWizard=false"' | sudo tee "$JENKINS_DEFAULT"

    # === Preconfigure Jenkins Admin via Groovy ===
    echo "🔐 Configuring Jenkins admin user..."
    sudo mkdir -p /var/lib/jenkins/init.groovy.d
    cat <<EOF | sudo tee /var/lib/jenkins/init.groovy.d/basic-security.groovy > /dev/null
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

    # === Add Jenkins user to sudo or wheel group ===
    echo "🔧 Adding 'jenkins' user to sudo/wheel group..."
    if getent group sudo >/dev/null 2>&1; then
        sudo usermod -aG sudo jenkins
    elif getent group wheel >/dev/null 2>&1; then
        sudo usermod -aG wheel jenkins
    fi

    echo "🚀 Starting Jenkins service..."
    sudo systemctl enable "$JENKINS_SERVICE"
    sudo systemctl restart "$JENKINS_SERVICE"
    sudo timedatectl set-timezone Asia/Kolkata
    sudo systemctl restart "$JENKINS_SERVICE"

    echo "✅ Jenkins setup complete!"
    echo "👤 Admin: $ADMIN_USER"
    echo "🔐 Password: $ADMIN_PASSWORD"
}

jenkins
echo "✅ Jenkins installation and configuration completed!"