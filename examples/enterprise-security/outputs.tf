# Cluster Information
output "cluster_id" {
  description = "The ID of the Redis Enterprise cluster"
  value       = module.redis_enterprise.cluster_id
}

output "cluster_name" {
  description = "The name of the Redis Enterprise cluster"
  value       = module.redis_enterprise.cluster_name
}

output "hostname" {
  description = "The hostname of the Redis Enterprise cluster"
  value       = module.redis_enterprise.hostname
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = data.azurerm_resource_group.main.name
}

# Database Information
output "database_id" {
  description = "The ID of the Redis database"
  value       = module.redis_enterprise.database_id
}

output "database_name" {
  description = "The name of the Redis database"
  value       = module.redis_enterprise.database_name
}

# Note: Access keys require additional data source or AzAPI call
# They are not directly exposed by azurerm_managed_redis resource
output "access_keys_note" {
  description = "Information about accessing keys"
  value       = "Access keys can be retrieved using: az redisenterprise database list-keys --cluster-name ${module.redis_enterprise.cluster_name} --resource-group ${data.azurerm_resource_group.main.name}"
}

# Network Information
output "private_endpoint_id" {
  description = "The ID of the private endpoint"
  value       = azurerm_private_endpoint.redis.id
}

output "private_ip_address" {
  description = "The private IP address of the Redis cluster"
  value       = try(azurerm_private_endpoint.redis.private_service_connection[0].private_ip_address, "N/A")
}

output "vnet_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.redis.id
}

# Security Information
output "managed_identity_redis_id" {
  description = "The ID of the Redis managed identity"
  value       = azurerm_user_assigned_identity.redis.id
}

output "managed_identity_keyvault_id" {
  description = "The ID of the Key Vault managed identity"
  value       = azurerm_user_assigned_identity.keyvault.id
}

output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.redis.id
}

output "customer_managed_key_id" {
  description = "The ID of the customer managed key"
  value       = azurerm_key_vault_key.redis.id
}

output "customer_managed_key_enabled" {
  description = "Whether customer managed key encryption is enabled"
  value       = true
}

# Connection Information
output "connection_string_format" {
  description = "Redis connection string format (retrieve key separately)"
  value       = "rediss://:<ACCESS_KEY>@${module.redis_enterprise.hostname}:${module.redis_enterprise.port}"
}

output "redis_cli_command_format" {
  description = "Command to connect using redis-cli (requires VNet access, retrieve key separately)"
  value       = "redis-cli -h ${module.redis_enterprise.hostname} -p ${module.redis_enterprise.port} --tls -a '<primary_key>' --no-auth-warning"
}

# Security Summary
output "security_features" {
  description = "Summary of enabled security features"
  value = {
    customer_managed_keys = true
    private_link          = true
    managed_identity      = true
    high_availability     = length(var.zones) > 1
    tls_version           = var.minimum_tls_version
    redis_modules         = false
  }
}
