# Create resource group (conditional)
resource "azurerm_resource_group" "main" {
  count = var.create_resource_group ? 1 : 0

  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment   = var.environment
    BusinessUnit  = var.business_unit
    Example       = "redis-high-availability"
    CriticalLevel = "tier1"
  }
}

# Get existing resource group (conditional)
data "azurerm_resource_group" "existing" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

# Deploy Redis Enterprise cluster with high availability
module "redis_enterprise" {
  source = "../../modules/managed-redis"

  name                = var.redis_name
  resource_group_name = var.create_resource_group ? azurerm_resource_group.main[0].name : data.azurerm_resource_group.existing[0].name
  location            = var.create_resource_group ? azurerm_resource_group.main[0].location : data.azurerm_resource_group.existing[0].location

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
