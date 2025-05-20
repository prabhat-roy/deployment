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

resource "null_resource" "update_jenkins_env" {
  triggers = {
    acr_name         = azurerm_container_registry.acr.name
    acr_login_server = azurerm_container_registry.acr.login_server
  }

  provisioner "local-exec" {
    environment = {
      ACR_NAME         = self.triggers.acr_name
      ACR_LOGIN_SERVER = self.triggers.acr_login_server
    }

    command = <<-EOT
      ENV_FILE="./Jenkins.env"

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
