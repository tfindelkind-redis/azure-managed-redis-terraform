# Key Vault for Customer Managed Keys
resource "azurerm_key_vault" "redis" {
  name                       = "kv-${var.redis_name}"
  location                   = var.location
  resource_group_name        = data.azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "premium"
  soft_delete_retention_days = 7
  purge_protection_enabled   = true

  # Enable RBAC for access control (recommended over access policies)
  rbac_authorization_enabled = true

  # Network settings - allow access for initial setup
  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"
  }

  tags = merge(var.tags, {
    "Purpose" = "Customer Managed Key Storage"
  })
}

# Customer Managed Key for Redis Encryption
resource "azurerm_key_vault_key" "redis" {
  name         = "cmk-${var.redis_name}"
  key_vault_id = azurerm_key_vault.redis.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  tags = merge(var.tags, {
    "Purpose" = "Redis Enterprise Encryption"
  })

  depends_on = [
    azurerm_role_assignment.current_user_kv_admin,
    azurerm_role_assignment.kv_crypto_user
  ]
}
