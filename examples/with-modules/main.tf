# Create resource group (conditional)
resource "azurerm_resource_group" "main" {
  count = var.create_resource_group ? 1 : 0

  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    Example     = "redis-with-modules"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Get existing resource group (conditional)
data "azurerm_resource_group" "existing" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

# Deploy Redis Enterprise cluster with multiple modules
module "redis_enterprise" {
  source = "../../modules/managed-redis"

  name                = var.redis_name
  resource_group_name = var.create_resource_group ? azurerm_resource_group.main[0].name : data.azurerm_resource_group.existing[0].name
  location            = var.create_resource_group ? azurerm_resource_group.main[0].location : data.azurerm_resource_group.existing[0].location

  # Larger SKU to support multiple modules
  sku = "Balanced_B1"

  # Enable multiple Redis modules based on variable
  modules = var.enable_all_modules ? [
    "RedisJSON",
    "RediSearch",
    "RedisBloom",
    "RedisTimeSeries"
    ] : [
    "RedisJSON",
    "RediSearch"
  ]

  # Enhanced configuration settings
  high_availability   = true
  minimum_tls_version = "1.2"
  client_protocol     = "Encrypted"
  eviction_policy     = "NoEviction" # Required for RediSearch module

  # Use AzAPI for now (will switch to native when available)
  use_azapi = true

  tags = {
    Environment = var.environment
    Example     = "redis-with-modules"
    Features    = "json,search,bloom,timeseries"
  }
}
