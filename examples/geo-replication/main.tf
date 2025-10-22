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
  primary_rg_id     = var.create_resource_groups ? azurerm_resource_group.primary[0].id : data.azurerm_resource_group.primary_existing[0].id
  secondary_rg_name = var.create_resource_groups ? azurerm_resource_group.secondary[0].name : data.azurerm_resource_group.secondary_existing[0].name
  secondary_rg_id   = var.create_resource_groups ? azurerm_resource_group.secondary[0].id : data.azurerm_resource_group.secondary_existing[0].id
}

# Primary Redis Enterprise cluster
resource "azapi_resource" "primary_cluster" {
  type      = "Microsoft.Cache/redisEnterprise@2025-05-01-preview"
  name      = "${var.project_name}-primary"
  location  = var.primary_location
  parent_id = local.primary_rg_id

  body = {
    sku = {
      name = var.redis_sku
    }

    properties = {
      highAvailability  = "Enabled"
      minimumTlsVersion = "1.2"
    }
  }

  tags = {
    Environment = var.environment
    Region      = "primary"
    Role        = "primary-redis"
    Criticality = "high"
    managed-by  = "terraform"
  }

  schema_validation_enabled = false

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

# Primary database with geo-replication configuration
resource "azapi_resource" "primary_database" {
  type      = "Microsoft.Cache/redisEnterprise/databases@2025-05-01-preview"
  name      = "default"
  parent_id = azapi_resource.primary_cluster.id

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

      # Geo-replication configuration - primary only includes itself initially
      geoReplication = {
        groupNickname = var.geo_replication_group_name
        linkedDatabases = [
          {
            id = "${azapi_resource.primary_cluster.id}/databases/default"
          }
        ]
      }
    }
  }

  schema_validation_enabled = false

  depends_on = [azapi_resource.primary_cluster]

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

# Secondary Redis Enterprise cluster (cluster only, database created separately for geo-replication)
resource "azapi_resource" "secondary_cluster" {
  type      = "Microsoft.Cache/redisEnterprise@2025-05-01-preview"
  name      = "${var.project_name}-secondary"
  location  = var.secondary_location
  parent_id = local.secondary_rg_id

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
  depends_on = [azapi_resource.primary_database]

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
            id = azapi_resource.primary_database.id
          },
          {
            id = "${azapi_resource.secondary_cluster.id}/databases/default"
          }
        ]
      }
    }
  }

  schema_validation_enabled = false

  # Wait for both clusters and primary database to be ready
  depends_on = [
    azapi_resource.primary_database,
    azapi_resource.secondary_cluster
  ]

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

# Data source to read primary cluster properties
data "azapi_resource" "primary_cluster_data" {
  type                   = "Microsoft.Cache/redisEnterprise@2025-05-01-preview"
  resource_id            = azapi_resource.primary_cluster.id
  response_export_values = ["properties"]

  depends_on = [azapi_resource.primary_cluster]
}

# Retrieve primary database access keys
data "azapi_resource_action" "primary_database_keys" {
  type        = "Microsoft.Cache/redisEnterprise/databases@2025-05-01-preview"
  resource_id = azapi_resource.primary_database.id
  action      = "listKeys"
  method      = "POST"

  response_export_values = ["primaryKey", "secondaryKey"]

  depends_on = [azapi_resource.primary_database]
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
