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
    ssh-keys = "${var.user}:${local.public_key_content}"
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
    user        = var.user
    private_key = local.private_key_content
  }

  # Copy update_upgrade_os.sh
  provisioner "file" {
    source      = "../../../shell_script/update_upgrade_os.sh"
    destination = "/tmp/update_upgrade_os.sh"
  }

  # Copy git.sh
  provisioner "file" {
    source      = "../../../shell_script/git.sh"
    destination = "/tmp/git.sh"
  }

  # Copy openjdk21.sh
  provisioner "file" {
    source      = "../../../shell_script/openjdk21.sh"
    destination = "/tmp/openjdk21.sh"
  }

  # Copy jenkins.sh script
  provisioner "file" {
    source      = "../../../shell_script/jenkins.sh"
    destination = "/tmp/jenkins.sh"
  }

  # Make executable and run with full logging
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/jenkins.sh",
      "chmod +x /tmp/git.sh",
      "chmod +x /tmp/update_upgrade_os.sh",
      "chmod +x /tmp/openjdk21.sh",
      "sudo /tmp/update_upgrade_os.sh 2>&1 | tee /tmp/update_upgrade_os.log",
      "sudo /tmp/git.sh 2>&1 | tee /tmp/git.log",
      "sudo /tmp/openjdk21.sh 2>&1 | tee /tmp/openjdk21.log",
      "sudo /tmp/jenkins.sh 2>&1 | tee /tmp/jenkins_install_full.log"
    ]
  }
}