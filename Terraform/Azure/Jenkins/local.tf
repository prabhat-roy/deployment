locals {
    subscription_id = var.subscription_id
  # Split the VNet CIDR into 2 subnets (public and private)
  # newbits = 8 means splitting /16 into /24 subnets
  subnet_prefixes = [
    cidrsubnet(var.vnet_cidr, 8, 0), # e.g. 10.1.0.0/24 - public
    cidrsubnet(var.vnet_cidr, 8, 1)  # e.g. 10.1.1.0/24 - private
  ]
}
