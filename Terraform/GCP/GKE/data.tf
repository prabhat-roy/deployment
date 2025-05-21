data "google_compute_network" "vpc" {
  name = var.vpc_name # pass VPC name as variable
}

data "google_compute_subnetwork" "private_subnet" {
  project = var.project_id
  region  = var.gcp_region
  name    = var.private_subnet_name

}
