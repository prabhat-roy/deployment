
data "azurerm_resource_group" "rg" {
  name = "kubernetes-deployment"
}

data "azurerm_virtual_network" "vnet" {
  name                = "azure-vnet"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "public_subnet" {
  name                 = "public-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
}

data "azurerm_subnet" "private_subnet" {
  name                 = "private-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
}

# (Optional) Get current client configuration for AKS access if needed
data "azurerm_client_config" "current" {}

# (Optional) Get the current subscription ID
data "azurerm_subscription" "current" {}