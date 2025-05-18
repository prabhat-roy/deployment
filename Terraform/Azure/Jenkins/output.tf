output "jenkins" {
  description = "URL to access Jenkins server"
  value       = "http://${azurerm_public_ip.jenkins_ip.ip_address}:8080"
}

output "sonarqube" {
  description = "URL to access Sonarqube server"
  value       = "http://${azurerm_public_ip.jenkins_ip.ip_address}:9000"
}
