provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Create Artifact Registry repositories for Docker images
resource "google_artifact_registry_repository" "repos" {
  for_each     = toset(var.gcr_repos)
  location     = var.gcp_region
  repository_id = each.key
  description  = "Terraform-managed Artifact Registry repo for ${each.key}"
  format       = "DOCKER"

  docker_config {
    immutable_tags = false
  }

}
