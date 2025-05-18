# Create Cloud Router
resource "google_compute_router" "router" {
  name    = "nat-router"
  region  = var.gcp_region
  network = google_compute_network.vpc.id
}
