resource "azurerm_role_definition" "jenkins_role" {
  name        = "JenkinsCustomRole"
  scope       = "/subscriptions/${var.subscription_id}"
  description = "Custom role for Jenkins VM with needed permissions"

  permissions {
    actions = [
      # VM management
      "Microsoft.Compute/virtualMachines/start/action",
      "Microsoft.Compute/virtualMachines/deallocate/action",

      # Resource group read permission (list resources)
      "Microsoft.Resources/subscriptions/resourceGroups/read",

      # AKS management
      "Microsoft.ContainerService/managedClusters/read",
      "Microsoft.ContainerService/managedClusters/write",
      "Microsoft.ContainerService/managedClusters/delete",
      "Microsoft.ContainerService/managedClusters/listClusterAdminCredential/action",

      # ACR management
      "Microsoft.ContainerRegistry/registries/read",
      "Microsoft.ContainerRegistry/registries/write",
      "Microsoft.ContainerRegistry/registries/delete",

      # ACR push/pull permissions (verify exact needed actions)
      "Microsoft.ContainerRegistry/registries/push",
      "Microsoft.ContainerRegistry/registries/pull",

      # Networking
      "Microsoft.Network/publicIPAddresses/*",

      # Uncomment if Jenkins will manage role assignments
      # "Microsoft.Authorization/roleAssignments/write",
      # "Microsoft.Authorization/roleAssignments/delete"
    ]
    not_actions = []
  }

  assignable_scopes = ["/subscriptions/${var.subscription_id}"]
}

resource "azurerm_role_assignment" "jenkins_vm_role_assignment" {
  scope              = "/subscriptions/${var.subscription_id}"
  role_definition_id = azurerm_role_definition.jenkins_role.role_definition_resource_id
  principal_id       = azurerm_linux_virtual_machine.jenkins.identity[0].principal_id
}
