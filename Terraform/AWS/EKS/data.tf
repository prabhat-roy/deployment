# Get the VPC by tag name
data "aws_vpc" "eks_vpc" {
  filter {
    name   = "tag:Name"
    values = ["VPC"]
  }
}

# Get private subnets in the VPC tagged for EKS
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.eks_vpc.id]
  }

filter {
    name   = "tag:Name"
    values = ["*Private*"]
  }
}

# Get public subnets in the VPC used for ELB
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.eks_vpc.id]
  }

filter {
    name   = "tag:Name"
    values = ["*Public*"]
  }
}

# Get available AZs in the current region
data "aws_availability_zones" "available" {
  state = "available"
}

# Get the latest Ubuntu AMI with HVM and gp3
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


output "private_subnets" {
  value = data.aws_subnets.private.ids
}

output "public_subnets" {
  value = data.aws_subnets.public.ids
}