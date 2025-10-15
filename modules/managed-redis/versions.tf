terraform {
  required_version = ">= 1.3"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.15"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}
