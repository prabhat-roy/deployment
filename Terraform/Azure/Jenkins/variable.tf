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
  description = "CIDR block for the Virtual Network"
}

variable "vm_size" {
  type        = string
  description = "VM size for Linux Virtual Machines"
}

variable "disk_size_gb" {
  type        = number
  description = "OS Disk size in GB for the VM"
}

variable "admin_user" {
  type        = string 
  description = "Admin username for VM login"
}

variable "aks_name" {
  type = string
  default = ""
}

variable "acr_name" {
  type = string
  default = ""
}