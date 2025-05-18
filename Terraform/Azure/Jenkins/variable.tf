variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID to deploy resources in"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the Azure Resource Group"
}

variable "location" {
  type        = string
  description = "Azure region for resource deployment"
}

variable "vnet_cidr" {
  type        = string
  default     = "10.1.0.0/16"
  description = "CIDR block for the Virtual Network"
}

variable "vm_size" {
  type        = string
  default     = "Standard_B1ms"
  description = "VM size for Linux Virtual Machines"
}

variable "disk_size_gb" {
  type        = number
  default     = 30
  description = "OS Disk size in GB for the VM"
}

variable "admin_user" {
  type        = string
  default     = "azureuser"
  description = "Admin username for VM login"
}
