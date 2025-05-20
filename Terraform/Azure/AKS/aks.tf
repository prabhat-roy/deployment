resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = var.azure_region
  resource_group_name = var.resource_group
  dns_prefix          = var.dns_prefix
  kubernetes_version = var.kubernetes_version


  default_node_pool {
    name           = "default"
    node_count = var.default_node_count
    os_sku = "Ubuntu"
    vm_size        = var.worker_node_size
    vnet_subnet_id = data.azurerm_subnet.private_subnet.id

    auto_scaling_enabled = true
 
    orchestrator_version = var.kubernetes_version

  }

  identity {
    type = "SystemAssigned"
  }

lifecycle {
    ignore_changes = [default_node_pool[0].node_count]
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    network_policy    = "azure"
    outbound_type     = "loadBalancer"
  }
}
