resource "aws_iam_instance_profile" "eks_nodes" {
  name = "eks-node-instance-profile"
  role = aws_iam_role.eks_worker_role.name
}