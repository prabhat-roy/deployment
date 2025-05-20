terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "4.29.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
  
}
