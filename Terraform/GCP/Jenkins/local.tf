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

}