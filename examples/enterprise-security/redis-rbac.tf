# Redis Cache Contributor role assignment for managed identity
# This allows the app service managed identity to access Redis using Entra ID authentication
# The role is assigned at the database level for data plane access

resource "azurerm_role_assignment" "redis_contributor" {
  scope                = module.redis_enterprise.database_id
  role_definition_name = "Redis Cache Contributor"
  principal_id         = azurerm_user_assigned_identity.redis.principal_id
  principal_type       = "ServicePrincipal"

  depends_on = [
    module.redis_enterprise,
    azurerm_user_assigned_identity.redis
  ]
}
