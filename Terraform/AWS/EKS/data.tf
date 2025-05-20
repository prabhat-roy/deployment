data "aws_vpc" "eks_vpc" {
    filter {
      name = "tag:Name"
      values = ["VPC"]

    }
}

data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.eks_vpc.id

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.eks_vpc.id

  tags = {
    "kubernetes.io/role/elb" = "1"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}