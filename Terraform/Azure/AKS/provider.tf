terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.29.0" # Latest stable as of May 2025
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.4" # Latest stable as of May 2025
    }
  }
}


provider "azurerm" {
  subscription_id = var.subscription_id
  features {}

}
