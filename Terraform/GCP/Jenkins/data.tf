data "http" "icanhazip" {
  url = "https://ipv4.icanhazip.com"
  request_headers = {
    Accept = "text/plain"
  }
}

data "google_compute_zones" "available" {
  region = var.gcp_region
}

data "google_compute_image" "ubuntu" {
  project = var.ubuntu_image_project
  family  = var.ubuntu_image_family
}