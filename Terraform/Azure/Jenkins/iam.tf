# Custom role for Jenkins with extended permissions (optional, kept for control)
resource "azurerm_role_definition" "jenkins_role" {
  name        = "JenkinsCustomRole"
  scope       = "/subscriptions/${var.subscription_id}"
  description = "Custom role for Jenkins VM to manage general infrastructure including ACR and AKS"

  permissions {
    actions = [
      # VM operations
      "Microsoft.Compute/virtualMachines/start/action",
      "Microsoft.Compute/virtualMachines/deallocate/action",
      
      # Resource group and deployments
      "Microsoft.Resources/subscriptions/resourceGroups/*",
      "Microsoft.Resources/deployments/*",

      # Networking
      "Microsoft.Network/*",

      # Container Registry (ACR)
      "Microsoft.ContainerRegistry/registries/*",

      # AKS
      "Microsoft.ContainerService/managedClusters/*",

      # Identity (for AKS & VM managed identities)
      "Microsoft.ManagedIdentity/userAssignedIdentities/*",

      # Storage
      "Microsoft.Storage/*"
    ]
    not_actions = []
  }

  assignable_scopes = [
    "/subscriptions/${var.subscription_id}"
  ]
}

# Assign the custom role to Jenkins VM (optional, use instead of built-in Contributor if you want fine control)
resource "azurerm_role_assignment" "jenkins_custom_role_assignment" {
  scope              = "/subscriptions/${var.subscription_id}"
  role_definition_id = azurerm_role_definition.jenkins_role.role_definition_resource_id
  principal_id       = azurerm_linux_virtual_machine.jenkins.identity[0].principal_id
}

# ✅ Assign built-in Contributor role to Jenkins VM (equivalent to AdministratorAccess in AWS)
resource "azurerm_role_assignment" "jenkins_contributor" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azurerm_linux_virtual_machine.jenkins.identity[0].principal_id
}

# Optional: Assign AcrPush if needed for image push operations
resource "azurerm_role_assignment" "jenkins_acr_push" {
  count                = local.acr_resource_id != "" ? 1 : 0
  scope                = local.acr_resource_id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_linux_virtual_machine.jenkins.identity[0].principal_id
}

# Optional: Assign AKS Admin role if Jenkins needs `kubectl` or cluster admin access
resource "azurerm_role_assignment" "jenkins_aks_admin" {
  count                = local.aks_resource_id != "" ? 1 : 0
  scope                = local.aks_resource_id
  role_definition_name = "Azure Kubernetes Service RBAC Admin"
  principal_id         = azurerm_linux_virtual_machine.jenkins.identity[0].principal_id
}
