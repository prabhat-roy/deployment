# Public Subnets
resource "google_compute_subnetwork" "public" {
  for_each                 = toset(local.zones)
  name                     = "public-${each.key}"
  ip_cidr_range            = "10.10.${index(local.zones, each.key)}.0/24"
  region                   = var.gcp_region
  network                  = google_compute_network.vpc.name
  private_ip_google_access = false
}

# Private Subnets
resource "google_compute_subnetwork" "private" {
  name                     = "private-subnet"
  ip_cidr_range            = "10.20.0.0/16"
  region                   = var.gcp_region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.21.0.0/16"
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.22.0.0/20"
  }
}

resource "google_compute_route" "public_internet" {
  name             = "public-subnet-internet-route"
  network          = google_compute_network.vpc.name
  dest_range       = "0.0.0.0/0"
  priority         = 1000
  next_hop_gateway = "default-internet-gateway"
  tags             = ["public"]
}

