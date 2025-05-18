resource "google_compute_network" "vpc" {
  project                         = var.project_id
  name                            = "gcp-vpc"
  delete_default_routes_on_create = false
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"

}