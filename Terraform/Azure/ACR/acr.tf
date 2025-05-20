resource "random_id" "acr_suffix" {
  byte_length = 4
}

resource "azurerm_container_registry" "acr" {
  name                = "kubernetes${random_id.acr_suffix.hex}"
  resource_group_name = var.resource_group
  location            = var.azure_region
  sku                 = "Standard"
  admin_enabled       = true

  tags = {
    CreatedBy = "Terraform"
  }
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}