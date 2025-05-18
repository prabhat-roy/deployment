resource "google_compute_firewall" "internal" {
  name    = "allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "all"
  }

  source_ranges = ["10.0.0.0/8"]
}

resource "google_compute_firewall" "ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = [22]
  }
  source_ranges = concat(
    [local.my_ip],
    local.gcp_browser_ips
  )
  direction = "INGRESS"
}

resource "google_compute_firewall" "jenkins" {
  name    = "jenkins-access"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = [8080]
  }
  source_ranges = ["0.0.0.0/0"]
  direction     = "INGRESS"
}

resource "google_compute_firewall" "sonarqube" {
  name    = "sonarqube-access"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = [9000]
  }
  source_ranges = ["0.0.0.0/0"]
  direction     = "INGRESS"
}

resource "google_compute_firewall" "allow_jenkins_to_gke_master" {
  name    = "allow-jenkins-to-gke-master"
  network = google_compute_network.vpc.name
   direction = "EGRESS"
   destination_ranges = ["10.100.0.0/28"]

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = [google_compute_instance.jenkins.network_interface[0].network_ip] # Jenkins private IP
  target_tags   = ["gke-master"] # You may need to add this tag to the master (or allow for master subnet)
}
