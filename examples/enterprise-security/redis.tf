# Redis Enterprise Cluster with Enterprise Security Features
# Using the NEW azurerm_managed_redis resource (replaces deprecated azurerm_redis_enterprise_cluster)
resource "azurerm_managed_redis" "main" {
  name                = var.redis_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location

  sku_name = var.sku_name

  # High Availability Configuration
  high_availability_enabled = true

  # Managed Identity Assignment
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.redis.id,
      azurerm_user_assigned_identity.keyvault.id
    ]
  }

  # Customer Managed Key Encryption
  customer_managed_key {
    key_vault_key_id          = azurerm_key_vault_key.redis.id
    user_assigned_identity_id = azurerm_user_assigned_identity.keyvault.id
  }

  # Default Database Configuration
  default_database {
    client_protocol   = "Encrypted"
    clustering_policy = "EnterpriseCluster"
    eviction_policy   = "NoEviction"

    # Redis Modules (conditionally enabled)
    dynamic "module" {
      for_each = var.enable_modules ? ["RedisJSON", "RediSearch"] : []
      content {
        name = module.value
      }
    }
  }

  tags = var.tags

  depends_on = [
    azurerm_role_assignment.kv_crypto_user,
    azurerm_key_vault_key.redis
  ]
}

