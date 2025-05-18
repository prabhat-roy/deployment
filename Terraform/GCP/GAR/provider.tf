terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.35.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.35.0"
    }

  }
}

provider "google" {
  project = var.project_id
  region  = var.gcp_region
}