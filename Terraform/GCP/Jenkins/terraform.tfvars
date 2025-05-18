project_id = "round-cable-405107"
gcp_region = "us-central1"

ubuntu_image_project = "ubuntu-os-cloud"
ubuntu_image_family  = "ubuntu-2404-lts-amd64"

machine_type = "e2-medium"
disk_size    = 50

user = "ubuntu"

public_key  = "~/.ssh/id_ed25519.pub"
private_key = "~/.ssh/id_ed25519"