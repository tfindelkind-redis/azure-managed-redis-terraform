# Primary region resource group
resource "azurerm_resource_group" "primary" {
  count    = var.create_resource_groups ? 1 : 0
  name     = var.primary_resource_group_name
  location = var.primary_location

  tags = {
    Environment = var.environment
    Region      = "primary"
    Purpose     = "geo-replication-redis"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Use existing primary resource group
data "azurerm_resource_group" "primary_existing" {
  count = var.create_resource_groups ? 0 : 1
  name  = var.primary_resource_group_name
}

# Secondary region resource group
resource "azurerm_resource_group" "secondary" {
  count    = var.create_resource_groups ? 1 : 0
  name     = var.secondary_resource_group_name
  location = var.secondary_location

  tags = {
    Environment = var.environment
    Region      = "secondary"
    Purpose     = "geo-replication-redis"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Use existing secondary resource group
data "azurerm_resource_group" "secondary_existing" {
  count = var.create_resource_groups ? 0 : 1
  name  = var.secondary_resource_group_name
}

# Local values for resource group references
locals {
  primary_rg_name   = var.create_resource_groups ? azurerm_resource_group.primary[0].name : data.azurerm_resource_group.primary_existing[0].name
  primary_location  = var.create_resource_groups ? azurerm_resource_group.primary[0].location : data.azurerm_resource_group.primary_existing[0].location
  secondary_rg_name = var.create_resource_groups ? azurerm_resource_group.secondary[0].name : data.azurerm_resource_group.secondary_existing[0].name
  secondary_location = var.create_resource_groups ? azurerm_resource_group.secondary[0].location : data.azurerm_resource_group.secondary_existing[0].location
}

# Primary Redis Enterprise cluster using module
module "redis_primary" {
  source = "../../modules/managed-redis"

  name                = "${var.project_name}-primary"
  resource_group_name = local.primary_rg_name
  location            = local.primary_location

  sku               = var.redis_sku
  high_availability = true
  minimum_tls_version = "1.2"

  # Database configuration
  client_protocol     = "Encrypted"
  eviction_policy     = "NoEviction"
  clustering_policy   = "EnterpriseCluster"

  # Redis modules
  modules = ["RedisJSON", "RediSearch"]

  # Geo-replication disabled initially - will be configured after secondary is created
  geo_replication_enabled = false

  # Persistence disabled for geo-replication
  persistence_aof_enabled = false
  persistence_rdb_enabled = false

  # Access keys authentication must be enabled
  access_keys_authentication_enabled = true
  defer_upgrade = "NotDeferred"

  # Use AzAPI provider
  use_azapi = true

  tags = {
    Environment = var.environment
    Region      = "primary"
    Role        = "primary-redis"
    Criticality = "high"
  }

  depends_on = [
    azurerm_resource_group.primary,
    data.azurerm_resource_group.primary_existing
  ]
}

# Secondary Redis Enterprise cluster using module
module "redis_secondary" {
  source = "../../modules/managed-redis"

  name                = "${var.project_name}-secondary"
  resource_group_name = local.secondary_rg_name
  location            = local.secondary_location

  sku               = var.redis_sku
  high_availability = true
  minimum_tls_version = "1.2"

  # Database configuration
  client_protocol     = "Encrypted"
  eviction_policy     = "NoEviction"
  clustering_policy   = "EnterpriseCluster"

  # Redis modules (must match primary)
  modules = ["RedisJSON", "RediSearch"]

  # Geo-replication configuration - includes both databases
  # This establishes the link after both clusters exist
  # Note: The secondary database ID will be added through terraform output after initial creation
  geo_replication_enabled         = var.enable_geo_replication_linking
  geo_replication_group_nickname  = var.geo_replication_group_name
  geo_replication_linked_database_ids = var.enable_geo_replication_linking ? [
    module.redis_primary.database_id
  ] : []

  # Persistence disabled for geo-replication
  persistence_aof_enabled = false
  persistence_rdb_enabled = false

  # Access keys authentication must be enabled
  access_keys_authentication_enabled = true
  defer_upgrade = "NotDeferred"

  # Use AzAPI provider
  use_azapi = true

  tags = {
    Environment  = var.environment
    Region       = "secondary"
    Role         = "secondary-redis"
    Criticality  = "high"
  }

  # Wait for primary to be ready
  depends_on = [
    module.redis_primary,
    azurerm_resource_group.secondary,
    data.azurerm_resource_group.secondary_existing
  ]
}
