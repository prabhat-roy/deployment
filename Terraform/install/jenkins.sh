#!/bin/bash
set -e

install_jenkins() {
    # === CONFIG ===
    ADMIN_USER="admin"
    ADMIN_PASSWORD="admin"

    # === Install Jenkins ===
    echo "📦 Installing Jenkins..."
    sudo mkdir -p /etc/apt/keyrings
    sudo wget -q -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian/jenkins.io-2023.key
    echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y jenkins

    # === Disable Setup Wizard ===
    echo 'JAVA_ARGS="-Djenkins.install.runSetupWizard=false"' | sudo tee /etc/default/jenkins

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

    # === Fix Permissions ===
    sudo chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d

    # === Add Jenkins user to sudo group ===
    echo "🔧 Adding 'jenkins' user to sudo group..."
    sudo usermod -aG sudo jenkins

    # === Start Jenkins ===
    echo "🚀 Starting Jenkins..."
    sudo systemctl enable jenkins
    sudo systemctl restart jenkins
    sudo timedatectl set-timezone Asia/Kolkata
    sudo systemctl restart jenkins

    # === Done ===
    echo "✅ Jenkins setup complete!"
    echo "👤 Admin: $ADMIN_USER"
    echo "🔐 Password: $ADMIN_PASSWORD"
}
