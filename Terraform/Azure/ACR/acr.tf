provider "azurerm" {
  features {}
}

resource "random_id" "acr_suffix" {
  byte_length = 4
}

# Create the Azure Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = "kubernetes${random_id.acr_suffix.hex}"
  resource_group_name = var.azure_resource_group
  location            = var.azure_location
  sku                 = "Standard"
  admin_enabled       = true

  tags = {
    CreatedBy = "Terraform"
  }
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}

# Update Jenkins.env file with ACR_NAME and ACR_LOGIN_SERVER
resource "null_resource" "update_jenkins_env" {
  triggers = {
    acr_name = azurerm_container_registry.acr.name
  }

  provisioner "local-exec" {
    command = <<EOT
#!/bin/bash
ENV_FILE="./Jenkins.env"
ACR_NAME="${azurerm_container_registry.acr.name}"

# Get login server using Azure CLI (az CLI must be installed and logged in)
ACR_LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --query "loginServer" --output tsv)

# Update or append ACR_NAME
if grep -q "^ACR_NAME=" "$ENV_FILE"; then
  sed -i "s/^ACR_NAME=.*/ACR_NAME=${ACR_NAME}/" "$ENV_FILE"
else
  echo "ACR_NAME=${ACR_NAME}" >> "$ENV_FILE"
fi

# Update or append ACR_LOGIN_SERVER
if grep -q "^ACR_LOGIN_SERVER=" "$ENV_FILE"; then
  sed -i "s|^ACR_LOGIN_SERVER=.*|ACR_LOGIN_SERVER=${ACR_LOGIN_SERVER}|" "$ENV_FILE"
else
  echo "ACR_LOGIN_SERVER=${ACR_LOGIN_SERVER}" >> "$ENV_FILE"
fi

echo "✅ Jenkins.env updated with ACR_NAME=${ACR_NAME} and ACR_LOGIN_SERVER=${ACR_LOGIN_SERVER}"
EOT
    interpreter = ["bash", "-c"]
  }

  depends_on = [azurerm_container_registry.acr]
}
