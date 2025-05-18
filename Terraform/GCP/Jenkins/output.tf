output "jenkins_url" {
  value       = "http://${google_compute_address.jenkins.address}:8080"
  description = "The URL of the Jenkins server"
}

output "sonarqube_url" {
  value       = "http://${google_compute_address.jenkins.address}:9000"
  description = "The URL of the Sonarqube server"
}
