resource "aws_eks_cluster" "eks-cluster" {
    name     = var.cluster_name
    role_arn = aws_iam_role.eks_cluster_role.arn
    version = var.eks_version
    vpc_config {
        subnet_ids         = slice(local.private_subnet_ids, 0, 3)
    }
    depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
  ]
}