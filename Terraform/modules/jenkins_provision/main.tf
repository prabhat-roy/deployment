resource "null_resource" "upload_scripts" {
  count = length(local.scripts_to_upload)

  connection {
    type        = local.ssh_type
    user        = local.ssh_user
    private_key = local.ssh_private_key
    host        = var.host
  }

  provisioner "file" {
    source      = "${local.script_dir}/${local.scripts_to_upload[count.index]}"
    destination = "/tmp/${local.scripts_to_upload[count.index]}"
  }
}

resource "null_resource" "run_wrapper" {
  connection {
    type        = local.ssh_type
    user        = local.ssh_user
    private_key = local.ssh_private_key
    host        = var.host
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/provision_jenkins.sh",
      "sudo /tmp/provision_jenkins.sh"
    ]
  }

  depends_on = [null_resource.upload_scripts]
}

resource "null_resource" "extra_files_copy_only" {
  count = length(local.extra_files)

  connection {
    type        = local.ssh_type
    user        = local.ssh_user
    private_key = local.ssh_private_key
    host        = var.host
  }

  provisioner "file" {
    source      = "${local.extra_files_source_dir}/${local.extra_files[count.index]}"
    destination = "/tmp/${local.extra_files[count.index]}"
  }
}
