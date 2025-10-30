# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Clusterless Redis with RDB + AOF Persistence
module "redis_clusterless" {
  source = "../../modules/managed-redis"

  name                = var.redis_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  # SKU Configuration
  sku = var.sku_name

  # CLUSTERLESS Configuration - Single shard deployment
  clustering_policy = "EnterpriseCluster"

  # PERSISTENCE Configuration
  persistence_rdb_enabled = true # RDB: Periodic snapshots
  persistence_aof_enabled = true # AOF: Every write logged

  # High Availability
  high_availability = true

  # Security
  minimum_tls_version = "1.2"
  client_protocol     = "Encrypted"

  # Redis Configuration
  eviction_policy = "AllKeysLRU"
  modules         = ["RedisJSON", "RediSearch"]

  # Provider - MUST use AzAPI for persistence
  use_azapi = true

  tags = var.tags

  depends_on = [azurerm_resource_group.main]
}
