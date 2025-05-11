variable "gcp_project_id" {
  type        = string
  description = "The GCP project ID"
}

variable "gcp_region" {
  type        = string
  description = "GCP region for Artifact Registry"
}

variable "gcr_repos" {
  type        = list(string)
  description = "List of Artifact Registry repositories to create"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment label for tagging"
}
