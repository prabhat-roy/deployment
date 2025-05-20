resource "aws_launch_template" "eks_nodes" {
  name_prefix   = "eks-nodes-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name = var.key_name
  
  iam_instance_profile {
    name = aws_iam_instance_profile.karpenter_instance_profile.name
  }

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

  tag_specifications {
  resource_type = "instance"
  tags = {
    "Name"                            = "karpenter-node"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

}
