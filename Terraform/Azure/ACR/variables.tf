variable "azure_region" {
  type        = string
  description = "Azure region for ACR"
}

variable "resource_group" {
  type        = string
  description = "Azure resource group name for ACR"
}

variable "acr_repo_names" {
  type        = list(string)
  description = "List of ACR repositories"
}

variable "subscription_id" {
  type = string
}