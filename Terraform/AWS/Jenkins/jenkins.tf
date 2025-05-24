resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public["az1"].id
  key_name               = aws_key_pair.existing_key.key_name
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
    private_key = file(var.private_key)
  }

  # Copy update_upgrade_os.sh
  provisioner "file" {
    source      = "../../../shell_script/update_upgrade_os.sh"
    destination = "/tmp/update_upgrade_os.sh"
  }

  # Copy install_jq.sh
  provisioner "file" {
    source      = "../../../shell_script/install_jq.sh"
    destination = "/tmp/install_jq.sh"
  }

  # Copy install_openjdk.sh
  provisioner "file" {
    source      = "../../../shell_script/install_openjdk.sh"
    destination = "/tmp/install_openjdk.sh"
  }

  # Copy install_jenkins.sh script
  provisioner "file" {
    source      = "../../../shell_script/install_jenkins.sh"
    destination = "/tmp/install_jenkins.sh"
  }

  # Copy install_jenkins_plugin.sh script
  provisioner "file" {
    source      = "../../../shell_script/install_jenkins_plugin.sh"
    destination = "/tmp/install_jenkins_plugin.sh"
  }

  # Copy jenkins_plugin.txt script
  provisioner "file" {
    source      = "../../../Jenkins/jenkins_plugin.txt"
    destination = "/tmp/jenkins_plugin.txt"
  }

# Copy jenkins_credential.sh script
  provisioner "file" {
    source      = "../../../shell_script/jenkins_credential.sh"
    destination = "/tmp/jenkins_credential.sh"
  }

   # Copy install_git.sh
  provisioner "file" {
    source      = "../../../shell_script/install_git.sh"
    destination = "/tmp/install_git.sh"
  }

   # Copy tools_jenkins_jdk.sh
  provisioner "file" {
    source      = "../../../shell_script/tools_jenkins_jdk.sh"
    destination = "/tmp/tools_jenkins_jdk.sh"
  }

#copy install_docker.sh
  provisioner "file" {
    source      = "../../../shell_script/install_docker.sh"
    destination = "/tmp/install_docker.sh"
  }

  # Make executable and run with full logging
  provisioner "remote-exec" {
    inline = [      
      "chmod +x /tmp/update_upgrade_os.sh",
      "chmod +x /tmp/install_jq.sh",
      "chmod +x /tmp/install_openjdk.sh",
      "chmod +x /tmp/install_jenkins.sh",
      "chmod +x /tmp/install_jenkins_plugin.sh",
      "chmod +x /tmp/jenkins_credential.sh",
      "chmod +x /tmp/install_git.sh",
      "chmod +x /tmp/tools_jenkins_jdk.sh",
      "chmod +x /tmp/install_docker.sh",
      "sudo /tmp/update_upgrade_os.sh 2>&1 | tee /tmp/update_upgrade_os.log",
      "sudo /tmp/install_jq.sh 2>&1 | tee /tmp/install_jq.log",
      "sudo /tmp/install_openjdk.sh 2>&1 | tee /tmp/openjdk21.log",
      "sudo /tmp/install_jenkins.sh 2>&1 | tee /tmp/install_jenkins.log",
      "sudo /tmp/install_jenkins_plugin.sh 2>&1 | tee /tmp/install_jenkins_plugin.log",
      "sudo /tmp/jenkins_credential.sh 2>&1 | tee /tmp/jenkins_credential.log",
      "sudo /tmp/install_git.sh 2>&1 | tee /tmp/install_git.log",
      "sudo /tmp/tools_jenkins_jdk.sh 2>&1 | tee /tmp/tools_jenkins_jdk.log",
      "sudo /tmp/install_docker.sh 2>&1 | tee /tmp/install_docker.log"
    ]
  }
}