# Primary region resource group
resource "azurerm_resource_group" "primary" {
  name     = "rg-azure-managed-redis-terraform"
  location = var.primary_location

  tags = {
    Environment = var.environment
    Region      = "primary"
    Purpose     = "geo-replication-redis"
  }
}

# Secondary region resource group
resource "azurerm_resource_group" "secondary" {
  name     = "rg-azure-managed-redis-terraform2"
  location = var.secondary_location

  tags = {
    Environment = var.environment
    Region      = "secondary"
    Purpose     = "geo-replication-redis"
  }
}

# Primary Redis Enterprise cluster
module "redis_primary" {
  source = "../../modules/managed-redis"

  name                = "${var.project_name}-primary"
  resource_group_name = azurerm_resource_group.primary.name
  location            = azurerm_resource_group.primary.location

  sku = var.redis_sku

  modules = [
    "RedisJSON",
    "RediSearch"
  ]

  high_availability   = true
  minimum_tls_version = "1.2"
  # Note: Balanced_B3 SKU has zone redundancy enabled by default
  # No need to explicitly specify zones parameter

  use_azapi = true

  tags = {
    Environment = var.environment
    Region      = "primary"
    Role        = "primary-redis"
    Criticality = "high"
  }
}

# Secondary Redis Enterprise cluster (cluster only, database created separately for geo-replication)
resource "azapi_resource" "secondary_cluster" {
  type      = "Microsoft.Cache/redisEnterprise@2025-05-01-preview"
  name      = "${var.project_name}-secondary"
  location  = azurerm_resource_group.secondary.location
  parent_id = azurerm_resource_group.secondary.id

  body = {
    sku = {
      name = var.redis_sku
    }

    properties = {
      highAvailability  = "Enabled"
      minimumTlsVersion = "1.2"
    }

    zones = null
  }

  tags = {
    Environment  = var.environment
    Region       = "secondary"
    Role         = "secondary-redis"
    Criticality  = "high"
    "managed-by" = "terraform"
  }

  schema_validation_enabled = false

  # Ensure primary is fully created first
  depends_on = [module.redis_primary]

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

# Secondary database with geo-replication configuration
resource "azapi_resource" "secondary_database" {
  type      = "Microsoft.Cache/redisEnterprise/databases@2025-05-01-preview"
  name      = "default"
  parent_id = azapi_resource.secondary_cluster.id

  body = {
    properties = {
      clientProtocol   = "Encrypted"
      evictionPolicy   = "NoEviction"
      clusteringPolicy = "EnterpriseCluster"

      modules = [
        {
          name = "RedisJSON"
        },
        {
          name = "RediSearch"
        }
      ]

      # Required properties for API version 2025-05-01-preview
      deferUpgrade             = "NotDeferred"
      accessKeysAuthentication = "Enabled"

      persistence = {
        aofEnabled = false
        rdbEnabled = false
      }

      # Geo-replication configuration
      geoReplication = {
        groupNickname = var.geo_replication_group_name
        linkedDatabases = [
          {
            id = module.redis_primary.database_id
          }
        ]
      }
    }
  }

  schema_validation_enabled = false

  # Wait for both clusters and primary database to be ready
  depends_on = [
    module.redis_primary,
    azapi_resource.secondary_cluster
  ]

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

# Data source to read secondary cluster properties
data "azapi_resource" "secondary_cluster_data" {
  type                   = "Microsoft.Cache/redisEnterprise@2025-05-01-preview"
  resource_id            = azapi_resource.secondary_cluster.id
  response_export_values = ["properties"]

  depends_on = [azapi_resource.secondary_cluster]
}

# Retrieve secondary database access keys
data "azapi_resource_action" "secondary_database_keys" {
  type        = "Microsoft.Cache/redisEnterprise/databases@2025-05-01-preview"
  resource_id = azapi_resource.secondary_database.id
  action      = "listKeys"
  method      = "POST"

  response_export_values = ["primaryKey", "secondaryKey"]

  depends_on = [azapi_resource.secondary_database]
}

# Traffic Manager profile for global load balancing (future enhancement)
# Note: This is a placeholder for when Azure Managed Redis supports Traffic Manager integration
/*
resource "azurerm_traffic_manager_profile" "redis" {
  name                = "${var.project_name}-traffic-manager"
  resource_group_name = azurerm_resource_group.primary.name

  traffic_routing_method = "Priority"

  dns_config {
    relative_name = "${var.project_name}-redis"
    ttl          = 100
  }

  monitor_config {
    protocol                    = "TCP"
    port                       = 10000
    path                       = ""
    interval_in_seconds        = 30
    timeout_in_seconds         = 10
    tolerated_number_of_failures = 3
  }

  tags = {
    Environment = var.environment
    Purpose     = "redis-load-balancing"
  }
}
*/
