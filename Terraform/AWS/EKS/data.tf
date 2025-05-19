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

data "aws_subnet" "private_metadata" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

data "aws_subnet" "public_metadata" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}

locals {
  available_azs = data.aws_availability_zones.available.names

  private_subnet_ids = [
    for subnet_id, subnet in data.aws_subnet.private_metadata :
    subnet_id if contains(local.available_azs, subnet.availability_zone)
  ]

  public_subnet_ids = [
    for subnet_id, subnet in data.aws_subnet.public_metadata :
    subnet_id if contains(local.available_azs, subnet.availability_zone)
  ]
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