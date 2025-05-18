locals {
  my_ip = "${trimspace(data.http.icanhazip.response_body)}/32"

  # GCP browser SSH IP range (official from GCP docs)
  gcp_browser_ips = ["35.235.240.0/20"]
  zones           = data.google_compute_zones.available.names
  default_zone    = element(data.google_compute_zones.available.names, 0)

  sa_roles = [
    "roles/compute.admin",            # Manage Compute Engine VMs & resources
    "roles/storage.admin",            # Access Google Cloud Storage buckets
    "roles/iam.serviceAccountUser",  # Impersonate/use service accounts (needed for GKE and others)
    "roles/container.admin",          # Full GKE cluster management
    "roles/artifactregistry.admin",  # Manage Artifact Registry (push/pull images)
    "roles/logging.logWriter",        # Write logs (optional but useful)
    "roles/monitoring.metricWriter",   # Write monitoring metrics (optional)
    "roles/serviceusage.serviceUsageAdmin"  
  ]

  public_key_path  = startswith(var.public_key, "~") ? abspath(replace(var.public_key, "~", var.HOME)) : abspath(var.public_key)
  private_key_path = startswith(var.private_key, "~") ? abspath(replace(var.private_key, "~", var.HOME)) : abspath(var.private_key)

  public_key_content  = file(local.public_key_path)
  private_key_content = file(local.private_key_path)
}