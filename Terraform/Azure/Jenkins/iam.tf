# Custom role with general permissions only
resource "azurerm_role_definition" "jenkins_role" {
  name        = "JenkinsCustomRole"
  scope       = "/subscriptions/${var.subscription_id}"
  description = "Custom role for Jenkins VM for general operations"

  permissions {
    actions = [
      "Microsoft.Compute/virtualMachines/start/action",
      "Microsoft.Compute/virtualMachines/deallocate/action",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Network/publicIPAddresses/*"
    ]
    not_actions = []
  }

  assignable_scopes = [
    "/subscriptions/${var.subscription_id}"
  ]
}

# Assign custom role to Jenkins VM
resource "azurerm_role_assignment" "jenkins_custom_role_assignment" {
  scope              = "/subscriptions/${var.subscription_id}"
  role_definition_id = azurerm_role_definition.jenkins_role.role_definition_resource_id
  principal_id       = azurerm_linux_virtual_machine.jenkins.identity[0].principal_id
}

# Optional ACR role assignment (evaluates to zero now)
resource "azurerm_role_assignment" "jenkins_acr_push" {
  count                = local.acr_resource_id != "" ? 1 : 0
  scope                = local.acr_resource_id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_linux_virtual_machine.jenkins.identity[0].principal_id
}

# Optional AKS role assignment (evaluates to zero now)
resource "azurerm_role_assignment" "jenkins_aks_admin" {
  count                = local.aks_resource_id != "" ? 1 : 0
  scope                = local.aks_resource_id
  role_definition_name = "Azure Kubernetes Service RBAC Admin"
  principal_id         = azurerm_linux_virtual_machine.jenkins.identity[0].principal_id
}
