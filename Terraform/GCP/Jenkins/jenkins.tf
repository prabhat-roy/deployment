resource "google_compute_instance" "jenkins" {
  name         = "jenkins-vm"
  machine_type = var.machine_type
  zone         = local.default_zone
  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = var.disk_size
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.public[local.default_zone].id

    access_config {
      nat_ip = google_compute_address.jenkins.address
    }
  }

  metadata = {
    ssh-keys = "${var.admin_user}:${file(var.public_key)}"
  }

  service_account {
    email  = google_service_account.jenkins_service_account.email
    scopes = ["cloud-platform"]
  }

}

resource "google_compute_address" "jenkins" {
  name    = "jenkins-public-ip"
  project = var.project_id
  region  = var.gcp_region
}

resource "null_resource" "jenkins_provision" {
  depends_on = [google_compute_instance.jenkins]

  connection {
    type        = "ssh"
    host        = google_compute_address.jenkins.address
    user        = var.admin_user
    private_key = file(var.private_key)
  }

  # ✅ Copy entire shell_script folder at once
  provisioner "file" {
    source      = "../../../shell_script/"
    destination = "/tmp"
  }

provisioner "file" {
    source      = "../../../Jenkins/jenkins_plugin.txt"
    destination = "/tmp/jenkins_plugin.txt"
  }
  # ✅ Run orchestrator script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_tools.sh",
      "sudo bash /tmp/install_tools.sh"
    ]
  }
}