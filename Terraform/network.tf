resource "aws_vpc" "vpc" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "VPC"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Internet Gateway"
  }
}
resource "aws_subnet" "public" {
  for_each = {
    for i, az in data.aws_availability_zones.available.names :
    format("az%d", i + 1) => {
      az         = az
      cidr_block = cidrsubnet(var.aws_vpc_cidr, 8, i)
    }
  }
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
  tags = {
    Name = "Public Subnet ${each.key}"
  }
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "Public Route Table"
  }
}
resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}
/*
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "NAT EIP"
  }
  depends_on = [aws_internet_gateway.igw]
}
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public["az1"].id

  tags = {
    Name = "NAT Gateway"
  }

}

resource "aws_subnet" "private" {
  for_each = {
    for i, az in data.aws_availability_zones.available.names :
    format("az%d", i + 1) => {
      az         = az
      cidr_block = cidrsubnet(var.aws_vpc_cidr, 8, i + length(data.aws_availability_zones.available.names))
    }
  }
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az
  tags = {
    Name = "Private Subnet ${each.key}"
  }
}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "Private Route Table"
  }
}
resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}
*/