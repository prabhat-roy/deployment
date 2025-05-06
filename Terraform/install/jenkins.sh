#!/bin/bash
# Update and upgrade the OS
set -e

install_jenkins() {
  echo "🔧 Installing Jenkins..."

  # Add the Jenkins repository key to the system
  sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

  # Add the Jenkins repository to the system
  echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null

  # Update the package index
  sudo apt update -y

  # Install Jenkins
  sudo apt install jenkins -y

  # Start Jenkins service
  sudo systemctl start jenkins

  # Enable Jenkins to start on boot
  sudo systemctl enable jenkins

  # Add Jenkins to sudo group
  sudo usermod -aG sudo jenkins
  
  # Add Jenkins to Docker group (important for Jenkins to run Docker containers)
  sudo usermod -aG docker jenkins

  # Print Jenkins version
  echo -n "✅ Jenkins version: "
  jenkins --version

  # Wait for Jenkins to start up
  echo "⏳ Waiting for Jenkins to start..."
  sleep 30

  # Retrieve the initial Jenkins admin password
  JENKINS_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
  echo "🔑 Jenkins initial password: $JENKINS_PASSWORD"

  # Optional: Set the Jenkins admin password (change 'newAdminPassword' to your desired password)
  NEW_PASSWORD="admin"
  echo "🔐 Setting Jenkins admin password to: $NEW_PASSWORD"
  curl -X POST -u admin:$JENKINS_PASSWORD \
       --data "password=$NEW_PASSWORD" \
       http://localhost:8080/jenkins/setting-security/update

  echo "✅ Admin password updated successfully"

  # Install plugins from the jenkins_plugin.sh file
  echo "🔧 Installing Jenkins plugins..."
  if [ -f "jenkins_plugin.sh" ]; then
      source jenkins_plugin.sh
  else
      echo "❌ jenkins_plugin.sh not found. Skipping plugin installation."
  fi

  # Restart Jenkins to apply all configurations
  echo "🔄 Restarting Jenkins to apply configurations..."
  sudo systemctl restart jenkins

  echo "✅ Jenkins is fully set up and running. You can access it at http://localhost:8080"
}
