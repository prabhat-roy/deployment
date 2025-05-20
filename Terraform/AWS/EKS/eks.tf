resource "aws_eks_cluster" "eks-cluster" {
    name     = var.cluster_name
    role_arn = aws_iam_role.eks_cluster_role.arn
    version = var.eks_version
    vpc_config {
        subnet_ids         = data.aws_subnet_ids.private.ids
        endpoint_private_access = true
        endpoint_public_access  = true
    }
    depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSServicePolicy
  ]
}