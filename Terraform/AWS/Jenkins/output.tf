output "jenkins_url" {
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
  description = "The URL of the Jenkins server"
}

output "sonarqube_url" {
  value       = "http://${aws_instance.jenkins.public_ip}:9000"
  description = "The URL of the Sonarqube server"
}
