variable "azure_location" {
  type        = string
  description = "Azure region for ACR"
}

variable "azure_resource_group" {
  type        = string
  description = "The Azure resource group name"
}

variable "azure_acr_name" {
  type        = string
  description = "The Azure Container Registry name"
}

variable "acr_repo_names" {
  type        = list(string)
  description = "List of repositories to create in ACR"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment label for tagging"
}
