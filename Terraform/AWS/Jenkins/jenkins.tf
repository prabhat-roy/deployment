resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public["az1"].id
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.jenkins.name
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    http_endpoint               = "enabled"
    instance_metadata_tags      = "enabled"
  }
  root_block_device {
    encrypted             = true
    volume_size           = var.disk_size
    volume_type           = "gp3"
    delete_on_termination = true
  }
  tags = {
    Name = "Jenkins Server"
  }
}

resource "null_resource" "jenkins_provision" {
  depends_on = [aws_instance.jenkins]

  connection {
    type        = "ssh"
    host        = aws_instance.jenkins.public_ip
    user        = "ubuntu"
    private_key = file(var.private_key_path)
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