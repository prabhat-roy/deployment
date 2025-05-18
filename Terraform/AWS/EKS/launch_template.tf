resource "aws_launch_template" "eks_nodes" {
  name_prefix   = "eks-nodes-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    http_endpoint               = "enabled"
    instance_metadata_tags      = "enabled"
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.eks_nodes.name
  }
}
