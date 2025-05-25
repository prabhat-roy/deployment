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