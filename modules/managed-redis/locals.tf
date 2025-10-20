locals {
  # Azure Redis Enterprise API version configuration
  # Updated to GA version (2025-07-01) from preview (2024-09-01-preview)
  # This is the first stable API version for Azure Managed Redis (GA: May 2025)
  redis_enterprise_api_version = "2025-07-01"

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
