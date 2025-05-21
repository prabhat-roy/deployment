resource "azurerm_linux_virtual_machine" "jenkins" {
  name                  = "jenkins"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = var.vm_size
  admin_username        = var.admin_user
  network_interface_ids = [azurerm_network_interface.jenkins_nic.id]

  source_image_reference {
    publisher = data.azurerm_platform_image.ubuntu_2404_lts.publisher
    offer     = data.azurerm_platform_image.ubuntu_2404_lts.offer
    sku       = data.azurerm_platform_image.ubuntu_2404_lts.sku
    version   = data.azurerm_platform_image.ubuntu_2404_lts.version
  }

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    name                 = "osdisk-ubuntu-2404"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.disk_size_gb
  }

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_user
    public_key = file("~/.ssh/id_ed25519.pub")
  }
}

resource "null_resource" "jenkins_provision" {
  depends_on = [azurerm_linux_virtual_machine.jenkins]

  connection {
    type        = "ssh"
    host        = azurerm_public_ip.jenkins_ip.ip_address
    user        = var.admin_user
    private_key = file("~/.ssh/id_ed25519")
    timeout     = "2m"
  }

  # Copy update_upgrade_os.sh
  provisioner "file" {
    source      = "../../../shell_script/update_upgrade_os.sh"
    destination = "/tmp/update_upgrade_os.sh"
  }

  # Copy install_git.sh
  provisioner "file" {
    source      = "../../../shell_script/install_git.sh"
    destination = "/tmp/git.sh"
  }

  # Copy install_openjdk21.sh
  provisioner "file" {
    source      = "../../../shell_script/install_openjdk21.sh"
    destination = "/tmp/openjdk21.sh"
  }

  # Copy install_jenkins.sh script
  provisioner "file" {
    source      = "../../../shell_script/install_jenkins.sh"
    destination = "/tmp/jenkins.sh"
  }

  # Make executable and run with full logging
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_jenkins.sh",
      "chmod +x /tmp/install_git.sh",
      "chmod +x /tmp/update_upgrade_os.sh",
      "chmod +x /tmp/install_openjdk21.sh",
      "sudo /tmp/update_upgrade_os.sh 2>&1 | tee /tmp/update_upgrade_os.log",
      "sudo /tmp/install_git.sh 2>&1 | tee /tmp/git.log",
      "sudo /tmp/install_openjdk21.sh 2>&1 | tee /tmp/openjdk21.log",
      "sudo /tmp/install_jenkins.sh 2>&1 | tee /tmp/jenkins_install_full.log"
    ]
  }
}