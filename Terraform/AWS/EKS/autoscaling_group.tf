resource "aws_autoscaling_group" "eks_workers" {
  name                      = "eks-worker-asg"
  max_size                  = 5
  min_size                  = 1
  desired_capacity          = 2
  vpc_zone_identifier       = slice(local.private_subnet_ids, 0, 3)
  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = "$Latest"
  }
  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }
  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}