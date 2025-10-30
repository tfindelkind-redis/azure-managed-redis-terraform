terraform {
  required_version = ">= 1.3"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.15"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.50" # Required for azurerm_managed_redis resource
    }
  }
}
