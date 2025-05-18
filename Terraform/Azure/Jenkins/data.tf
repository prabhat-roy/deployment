data "http" "icanhazip" {
  url = "https://ipv4.icanhazip.com"
  request_headers = {
    Accept = "text/plain"
  }
}

data "azurerm_platform_image" "ubuntu_2404_lts" {
  location = azurerm_resource_group.rg.location

  publisher = "Canonical"
  offer     = "ubuntu-24_04-lts"
  sku       = "server-gen1"
  version   = "24.04.202407160"
}