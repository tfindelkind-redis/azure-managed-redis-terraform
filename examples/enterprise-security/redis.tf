# Redis Enterprise Cluster with Enterprise Security Features
# Using our module with AzureRM provider support

module "redis_enterprise" {
  source = "../../modules/managed-redis"

  name                = var.redis_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location

  # SKU Configuration
  sku               = var.sku_name
  high_availability = true

  # Security Configuration
  minimum_tls_version = "1.2"
  client_protocol     = "Encrypted"
  clustering_policy   = "EnterpriseCluster"
  eviction_policy     = "NoEviction"

  # Disable access keys authentication (use Entra ID instead)
  access_keys_authentication_enabled = false

  # Managed Identity Configuration
  identity_type = "UserAssigned"
  identity_ids = [
    azurerm_user_assigned_identity.redis.id,
    azurerm_user_assigned_identity.keyvault.id
  ]

  # Customer Managed Key (CMK) Encryption
  customer_managed_key_enabled      = var.use_byok
  customer_managed_key_vault_key_id = var.use_byok ? azurerm_key_vault_key.redis.id : null
  customer_managed_key_identity_id  = var.use_byok ? azurerm_user_assigned_identity.keyvault.id : null

  # Provider Selection
  use_azapi = var.use_azapi

  tags = var.tags

  depends_on = [
    azurerm_role_assignment.kv_crypto_user,
    azurerm_key_vault_key.redis,
    time_sleep.wait_for_rbac
  ]
}
