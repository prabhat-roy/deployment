resource "google_project_service" "container" {
  service = "container.googleapis.com"
  project = var.project_id
}

resource "google_project_service" "compute" {
  service = "compute.googleapis.com"
  project = var.project_id
}

resource "google_project_service" "iam" {
  service = "iam.googleapis.com"
  project = var.project_id
}

resource "google_project_service" "cloudresourcemanager" {
  service = "cloudresourcemanager.googleapis.com"
  project = var.project_id
}

resource "google_container_cluster" "gke_cluster" {
  name     = "gke-cluster"
  location = var.gcp_region
  project  = var.project_id

  networking_mode = "VPC_NATIVE"
  network         = data.google_compute_network.vpc.self_link
  subnetwork      = data.google_compute_subnetwork.private_subnet.self_link

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = "10.100.0.0/28"
  }

  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "primary_nodes" {
  cluster  = google_container_cluster.gke_cluster.name
  location = var.gcp_region

  node_count = 1

  node_config {
    machine_type = var.worker_node_size
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    tags = ["gke-node"]
  }
  
}
