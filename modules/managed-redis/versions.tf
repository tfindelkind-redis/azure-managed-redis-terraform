terraform {
  required_version = ">= 1.3"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.60" # Required for azurerm_managed_redis_access_policy_assignment (4.60+)
    }
  }
}
