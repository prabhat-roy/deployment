locals {
  subscription_id = var.subscription_id

  subnet_prefixes = [
    cidrsubnet(var.vnet_cidr, 8, 0), # Public subnet
    cidrsubnet(var.vnet_cidr, 8, 1)  # Private subnet
  ]

  aks_resource_id = var.aks_name != "" && var.resource_group_name != "" ? "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.ContainerService/managedClusters/${var.aks_name}" : ""

  acr_resource_id = var.acr_name != "" && var.resource_group_name != "" ? "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.ContainerRegistry/registries/${var.acr_name}" : ""
}
