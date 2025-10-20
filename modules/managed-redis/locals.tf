locals {
  # API version for Redis Enterprise resources
  redis_enterprise_api_version = "2025-05-01-preview"

  # Common tags to apply to all resources
  common_tags = merge(var.tags, {
    "managed-by" = "terraform"
    "module"     = "azure-managed-redis"
  })

  # Resource group ID for use in AzAPI resources
  resource_group_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"

  # Construct modules array for API body
  modules_config = [
    for module in var.modules : {
      name = module
    }
  ]

  # SKU configuration mapping
  sku_config = {
    name = var.sku
  }

  # High availability configuration
  ha_config = var.high_availability ? "Enabled" : "Disabled"

  # Zones configuration (only if specified)
  zones_config = length(var.zones) > 0 ? var.zones : null
}
