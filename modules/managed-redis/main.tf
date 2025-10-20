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
    properties = {
      clientProtocol   = var.client_protocol
      evictionPolicy   = var.eviction_policy
      clusteringPolicy = var.clustering_policy
      modules          = local.modules_config

      # Required for API version 2025-05-01-preview and later
      deferUpgrade             = "NotDeferred"
      accessKeysAuthentication = "Enabled" # Must be Enabled to use listKeys operation

      persistence = {
        aofEnabled = false
        rdbEnabled = false
      }
    }
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

# Future: Native azurerm implementation will go here
# This section will be populated when azurerm provider adds support
# for Azure Managed Redis resources

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
