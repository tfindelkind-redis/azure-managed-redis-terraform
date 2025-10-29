# Redis Cache Contributor role assignment for managed identity
# This allows the app service managed identity to access Redis
# Note: For data plane access with Entra ID, Redis Enterprise requires access keys
# to be enabled OR using the management API to get connection credentials

resource "azurerm_role_assignment" "redis_contributor" {
  scope                = azurerm_managed_redis.main.id
  role_definition_name = "Redis Cache Contributor"
  principal_id         = azurerm_user_assigned_identity.redis.principal_id
  principal_type       = "ServicePrincipal"

  depends_on = [
    azurerm_managed_redis.main,
    azurerm_user_assigned_identity.redis
  ]
}
