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
 min_count           = 1
  max_count           = 1
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


resource "azurerm_kubernetes_cluster_node_pool" "custom" {
  name                  = "customnp"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_DS2_v2"
  auto_scaling_enabled = true
  min_count             = 0
  max_count             = 2
  mode                  = "User"
  orchestrator_version  = azurerm_kubernetes_cluster.aks.kubernetes_version

  node_labels = {
    role = "custom"
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

resource "null_resource" "delete_default_pool" {
  count = var.remove_default_pool ? 1 : 0

  provisioner "local-exec" {
    command = <<EOT
      az aks nodepool delete \
        --resource-group ${var.resource_group} \
        --cluster-name aks-cluster \
        --name default \
        --yes
    EOT
  }

  depends_on = [azurerm_kubernetes_cluster_node_pool.custom]
}