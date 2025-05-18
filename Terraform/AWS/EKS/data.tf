data "aws_vpc" "eks_vpc" {
    filter {
      name = "tag:Name"
      values = ["VPC"]

    }
}

data "aws_subnets" "public" {
    filter {
      name = "tag:Name"
      values = ["Public*"]
    }
}

data "aws_subnets" "private" {
    filter {
      name = "tag:Name"
      values = ["Private*"]
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