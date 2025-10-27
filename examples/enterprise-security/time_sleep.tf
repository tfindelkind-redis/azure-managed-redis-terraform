# Time delay to allow role assignments to propagate
# CMK encryption requires the managed identity to have proper permissions
# before the Redis cluster can be created
resource "time_sleep" "wait_for_rbac" {
  depends_on = [
    azurerm_role_assignment.kv_crypto_user,
    azurerm_key_vault_key.redis
  ]

  create_duration = "60s"
}
