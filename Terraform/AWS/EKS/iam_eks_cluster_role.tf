resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"
  assume_role_policy = file("eks-cluster-assume-role-policy.json")
}

resource "aws_iam_role_policy" "eks_cluster_policy" {
  name   = "eks-cluster-policy"
  role   = aws_iam_role.eks_cluster_role.id
  policy = file("eks-cluster-policy.json")
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
