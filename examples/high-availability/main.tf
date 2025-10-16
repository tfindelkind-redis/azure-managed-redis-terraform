# Create resource group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment   = var.environment
    BusinessUnit  = var.business_unit
    Example       = "redis-high-availability"
    CriticalLevel = "tier1"
  }
}

# Deploy Redis Enterprise cluster with high availability
module "redis_enterprise" {
  source = "../../modules/managed-redis"

  name                = var.redis_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  # Production SKU for performance and reliability
  sku = "Balanced_B3"

  # Essential modules for production workloads
  modules = [
    "RedisJSON",
    "RediSearch"
  ]

  # High availability and security settings
  high_availability   = true
  minimum_tls_version = "1.2"
  client_protocol     = "Encrypted"
  eviction_policy     = "AllKeysLRU"

  # Multi-AZ deployment for maximum availability
  zones = var.availability_zones

  # Use AzAPI for now (will switch to native when available)  
  use_azapi = true

  tags = {
    Environment       = var.environment
    BusinessUnit      = var.business_unit
    Example           = "redis-high-availability"
    CriticalLevel     = "tier1"
    BackupPolicy      = "daily"
    MonitoringEnabled = "true"
  }
}
