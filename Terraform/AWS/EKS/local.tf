locals {
  # List of AZs supported by current AWS region
  available_azs = data.aws_availability_zones.available.names

  # Filter only private subnets in AZs available in this region
  private_subnet_ids = [
    for subnet_id, subnet in data.aws_subnet.private_metadata :
    subnet_id if contains(local.available_azs, subnet.availability_zone)
  ]

  public_subnet_ids = [
    for subnet_id, subnet in data.aws_subnet.public_metadata :
    subnet_id if contains(local.available_azs, subnet.availability_zone)
  ]

  # Extract corresponding AZs from filtered private subnets
  private_subnet_azs = distinct([
    for _, subnet in data.aws_subnet.private_metadata :
    subnet.availability_zone if contains(local.available_azs, subnet.availability_zone)
  ])

  # Ensure EKS only gets 2–3 valid AZs
  control_plane_subnets = slice(local.private_subnet_ids, 0, 3)
}
