provider "azurerm" {
  features {}
}

# Create the Resource Group for Azure ACR
resource "azurerm_resource_group" "main" {
  name     = var.azure_resource_group
  location = var.azure_location
}

# Create the Azure Container Registry (ACR)
resource "azurerm_container_registry" "main" {
  name                = var.azure_acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  admin_enabled       = true

  tags = {
    CreatedBy   = "Terraform"
    Environment = var.environment
  }
}

# Create repositories in ACR using az CLI (due to lazy creation in ACR)
resource "null_resource" "acr_repos" {
  for_each = toset(var.acr_repo_names)

  provisioner "local-exec" {
    command = <<EOT
az acr repository show --name ${var.azure_acr_name} --repository ${each.key} || \
echo "📦 Dummy push required to initialize repo '${each.key}' in ACR (repos are lazy-created on push)."
EOT
  }

  depends_on = [azurerm_container_registry.main]
}
