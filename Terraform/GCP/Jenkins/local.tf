locals {
  my_ip = "${trimspace(data.http.icanhazip.response_body)}/32"

  # GCP browser SSH IP range (official from GCP docs)
  gcp_browser_ips = ["35.235.240.0/20"]
  zones           = data.google_compute_zones.available.names
  default_zone    = element(data.google_compute_zones.available.names, 0)

  sa_roles = [
    "roles/compute.admin",
  "roles/compute.networkAdmin",
  "roles/compute.securityAdmin",
  "roles/storage.admin",
  "roles/iam.serviceAccountUser",
  "roles/iam.serviceAccountAdmin",
  "roles/iam.roleViewer",
  "roles/resourcemanager.projectIamAdmin",
  "roles/container.admin",
  "roles/artifactregistry.admin",
  "roles/logging.logWriter",
  "roles/monitoring.metricWriter",
  "roles/serviceusage.serviceUsageAdmin",
  "roles/dns.admin"
  ]

  public_key_path  = startswith(var.public_key, "~") ? abspath(replace(var.public_key, "~", var.HOME)) : abspath(var.public_key)
  private_key_path = startswith(var.private_key, "~") ? abspath(replace(var.private_key, "~", var.HOME)) : abspath(var.private_key)

  public_key_content  = file(local.public_key_path)
  private_key_content = file(local.private_key_path)
}