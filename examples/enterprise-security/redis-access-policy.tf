# Redis Enterprise Access Policy for Entra ID Authentication
# Required when accessKeysAuthentication is disabled

# Create access policy assignment for the managed identity
resource "azurerm_redis_enterprise_database_access_policy_assignment" "redis_access" {
  resource_group_name = data.azurerm_resource_group.main.name
  cluster_name        = azurerm_redis_enterprise_cluster.main.name
  database_name       = azurerm_redis_enterprise_database.main.name
  
  name                = "access-policy-${local.suffix}"
  access_policy_name  = "Data Contributor"  # Built-in policy for read/write access
  object_id           = azurerm_user_assigned_identity.redis.principal_id
  object_id_alias     = "ServicePrincipal"
}
