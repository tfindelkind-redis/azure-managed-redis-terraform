# Key Vault for Customer Managed Keys
resource "azurerm_key_vault" "redis" {
  # Use simple pattern if it fits (<=24 chars), otherwise truncate and remove hyphens
  name                       = length("kv-${var.redis_name}") <= 24 ? "kv-${var.redis_name}" : "kv-${replace(substr(var.redis_name, 0, 20), "-", "")}"
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

# ============================================================================
# BYOK (Bring Your Own Key) Support
# ============================================================================

# Import user-provided key (when use_byok = true)
resource "null_resource" "import_byok_key" {
  count = var.use_byok ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      # Check if key file exists
      if [ ! -f "${path.module}/${var.byok_key_file_path}" ]; then
        echo "❌ Error: ${var.byok_key_file_path} not found!"
        echo "Run: ./scripts/generate-byok-key.sh"
        exit 1
      fi

      echo "🔑 Importing BYOK encryption key to Key Vault..."
      
      # Import the key to Key Vault
      az keyvault key import \
        --vault-name ${azurerm_key_vault.redis.name} \
        --name cmk-${var.redis_name} \
        --pem-file ${path.module}/${var.byok_key_file_path} \
        --protection software
      
      echo "✅ Key imported successfully"
    EOT
  }

  depends_on = [
    azurerm_key_vault.redis,
    azurerm_role_assignment.current_user_kv_admin,
    azurerm_role_assignment.kv_crypto_user
  ]

  triggers = {
    key_file_hash = filemd5("${path.module}/${var.byok_key_file_path}")
    key_vault_id  = azurerm_key_vault.redis.id
  }
}
