region           = "us-east-1"
aws_vpc_cidr     = "10.0.0.0/16"
key_name         = "jenkins-key"
public_key_path = "~/.ssh/id_ed25519.pub"
private_key = "~/.ssh/id_ed25519"
instance_type    = "t2.medium"
disk_size        = 50
cluster_name     = "eks-cluster"