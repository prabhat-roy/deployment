resource "google_service_account" "jenkins_service_account" {
  account_id   = "jenkins-admin"
  display_name = "Jenkins Admin VM Service Account"
}

resource "google_project_iam_member" "vm_sa_roles" {
  for_each = toset(local.sa_roles)

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.jenkins_service_account.email}"
}