# Create resource group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    Example     = "redis-with-modules"
  }
}

# Deploy Redis Enterprise cluster with multiple modules
module "redis_enterprise" {
  source = "../../modules/managed-redis"

  name                = var.redis_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

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
  eviction_policy     = "AllKeysLRU" # Better for cache use cases

  # Use AzAPI for now (will switch to native when available)
  use_azapi = true

  tags = {
    Environment = var.environment
    Example     = "redis-with-modules"
    Features    = "json,search,bloom,timeseries"
  }
}
