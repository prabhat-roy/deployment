resource "aws_autoscaling_group" "eks_workers" {
  name                      = "eks-worker-asg"
  max_size                  = 5
  min_size                  = 1
  desired_capacity          = 2
  vpc_zone_identifier       = local.private_subnet_ids

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }
}
