# User-Assigned Managed Identity for Redis Enterprise
resource "azurerm_user_assigned_identity" "redis" {
  name                = "id-${var.redis_name}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location

  tags = var.tags
}

# User-Assigned Managed Identity for Key Vault Access
resource "azurerm_user_assigned_identity" "keyvault" {
  name                = "id-${var.redis_name}-kv"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location

  tags = merge(var.tags, {
    "Purpose" = "Key Vault CMK Access"
  })
}

# Role assignment: Key Vault Crypto Service Encryption User for CMK
resource "azurerm_role_assignment" "kv_crypto_user" {
  scope                = azurerm_key_vault.redis.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.keyvault.principal_id
}

# Role assignment: Current user as Key Vault Administrator (for key creation)
resource "azurerm_role_assignment" "current_user_kv_admin" {
  scope                = azurerm_key_vault.redis.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}
