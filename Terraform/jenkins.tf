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
    volume_size           = 20
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

  # Ensure the /tmp/install directory exists first
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /tmp/install"
    ]
  }

  # Copy install folder contents
  provisioner "file" {
    source      = "install/"
    destination = "/tmp/install/"
  }

  # Copy jenkins.sh script
  provisioner "file" {
    source      = "jenkins.sh"
    destination = "/tmp/jenkins.sh"
  }

  # Make executable and run with full logging
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/jenkins.sh",
      "sudo /tmp/jenkins.sh 2>&1 | tee /tmp/jenkins_install_full.log"
    ]
  }
}