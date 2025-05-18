resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix
  kubernetes_version = var.kubernetes_version


  default_node_pool {
    name           = "default"
    os_sku = "Ubuntu"
    vm_size        = var.worker_node_size
    vnet_subnet_id = data.azurerm_subnet.subnet.id

    auto_scaling_enabled = true
    min_count           = var.min_node_count
    max_count           = var.max_node_count

    os_disk_size_gb = 20
    type            = "VirtualMachineScaleSets"

  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    network_policy    = "azure"
    outbound_type     = "loadBalancer"
  }
}
