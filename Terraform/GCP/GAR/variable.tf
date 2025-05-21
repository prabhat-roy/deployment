variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
}

variable "gar_repos" {
  description = "List of GAR repositories to create"
  type        = list(string)
}