# Data sources
data "azurerm_client_config" "current" {}

# Redis Enterprise Cluster (AzAPI Implementation)
resource "azapi_resource" "cluster" {
  count = var.use_azapi ? 1 : 0

  type      = "Microsoft.Cache/redisEnterprise@${local.redis_enterprise_api_version}"
  name      = var.name
  location  = var.location
  parent_id = local.resource_group_id

  body = {
    sku = local.sku_config

    properties = {
      highAvailability  = local.ha_config
      minimumTlsVersion = var.minimum_tls_version
    }

    zones = local.zones_config
  }

  tags = local.common_tags

  schema_validation_enabled = false

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

# Data source to read cluster properties after creation (AzAPI Implementation)
data "azapi_resource" "cluster_data" {
  count = var.use_azapi ? 1 : 0

  type                   = "Microsoft.Cache/redisEnterprise@${local.redis_enterprise_api_version}"
  resource_id            = azapi_resource.cluster[0].id
  response_export_values = ["properties"]

  depends_on = [azapi_resource.cluster]
}

# Redis Database within the cluster (AzAPI Implementation)
resource "azapi_resource" "database" {
  count = var.use_azapi ? 1 : 0

  type      = "Microsoft.Cache/redisEnterprise/databases@${local.redis_enterprise_api_version}"
  name      = var.database_name
  parent_id = azapi_resource.cluster[0].id

  body = {
    properties = merge(
      {
        clientProtocol   = var.client_protocol
        evictionPolicy   = var.eviction_policy
        clusteringPolicy = var.clustering_policy
        modules          = local.modules_config

        # Required for API version 2025-05-01-preview and later
        deferUpgrade             = var.defer_upgrade
        accessKeysAuthentication = var.access_keys_authentication_enabled ? "Enabled" : "Disabled"

        persistence = {
          aofEnabled = var.persistence_aof_enabled
          rdbEnabled = var.persistence_rdb_enabled
        }
      },
      var.geo_replication_enabled ? {
        geoReplication = {
          groupNickname   = var.geo_replication_group_nickname
          linkedDatabases = [for db_id in var.geo_replication_linked_database_ids : { id = db_id }]
        }
      } : {}
    )
  }

  schema_validation_enabled = false

  depends_on = [azapi_resource.cluster]

  timeouts {
    create = "20m"
    update = "20m"
    delete = "20m"
  }
}

# Retrieve database access keys (AzAPI Implementation)
data "azapi_resource_action" "database_keys" {
  count = var.use_azapi ? 1 : 0

  type        = "Microsoft.Cache/redisEnterprise/databases@${local.redis_enterprise_api_version}"
  resource_id = azapi_resource.database[0].id
  action      = "listKeys"
  method      = "POST"

  response_export_values = ["primaryKey", "secondaryKey"]

  depends_on = [azapi_resource.database]
}

# ==============================================================================
# Native AzureRM Implementation (v4.50+)
# ==============================================================================

# Redis Managed cluster and database (AzureRM Implementation)
resource "azurerm_managed_redis" "cluster" {
  count = var.use_azapi ? 0 : 1

  name                      = var.name
  resource_group_name       = var.resource_group_name
  location                  = var.location
  sku_name                  = var.sku
  high_availability_enabled = var.high_availability

  # Managed Identity configuration (optional)
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type != "SystemAssigned" ? var.identity_ids : null
    }
  }

  # Customer Managed Key encryption (optional)
  dynamic "customer_managed_key" {
    for_each = var.customer_managed_key_enabled ? [1] : []
    content {
      key_vault_key_id          = var.customer_managed_key_vault_key_id
      user_assigned_identity_id = var.customer_managed_key_identity_id
    }
  }

  default_database {
    access_keys_authentication_enabled = var.access_keys_authentication_enabled
    client_protocol                     = var.client_protocol
    clustering_policy                   = var.clustering_policy
    eviction_policy                     = var.eviction_policy

    # Enable modules if specified
    dynamic "module" {
      for_each = var.modules
      content {
        name = module.value
      }
    }
  }

  tags = local.common_tags

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

/*
# Deprecated: Old placeholder for reference
# The above implementation replaces this placeholder
#
# This section was a placeholder before azurerm_managed_redis was available.
# Now implemented with full feature support above.

/*
# Placeholder for future native azurerm implementation
resource "azurerm_redis_enterprise_cluster" "main" {
  count = var.use_azapi ? 0 : 1
  
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = var.sku
  
  # Additional configuration will be added when provider supports it
}

resource "azurerm_redis_enterprise_database" "main" {
  count = var.use_azapi ? 0 : 1
  
  name               = var.database_name
  cluster_id         = azurerm_redis_enterprise_cluster.main[0].id
  client_protocol    = var.client_protocol
  eviction_policy    = var.eviction_policy
  clustering_policy  = var.clustering_policy
  
  # Module configuration will be added when provider supports it
}
*/
