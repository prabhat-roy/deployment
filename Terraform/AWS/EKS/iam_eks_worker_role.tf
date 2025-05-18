resource "aws_iam_role" "eks_worker_role" {
  name = "eks-worker-role"
  assume_role_policy = file("eks-worker-assume-role-policy.json")
}

resource "aws_iam_role_policy" "eks_worker_policy" {
  name   = "eks-worker-policy"
  role   = aws_iam_role.eks_worker_role.id
  policy = file("eks-worker-policy.json")
}

resource "aws_iam_role_policy_attachment" "eks_worker_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_worker_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy" "cni_policy" {
  name   = "AmazonVPC-CNIPolicy"
  role   = aws_iam_role.eks_worker_role.id
  policy = file("cni-policy.json")
}

resource "aws_iam_role_policy" "ebs_csi_driver_policy" {
  name   = "AmazonEBSCSIDriverPolicy"
  role   = aws_iam_role.eks_worker_role.id
  policy = file("ebs-csi-driver-policy.json")
}
