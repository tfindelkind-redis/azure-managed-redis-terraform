output "cluster_id" {
  description = "The ID of the Redis Enterprise cluster"
  value       = var.use_azapi ? azapi_resource.cluster[0].id : azurerm_managed_redis.cluster[0].id
}

output "cluster_name" {
  description = "The name of the Redis Enterprise cluster"
  value       = var.name
}

output "database_id" {
  description = "The ID of the Redis database"
  value       = var.use_azapi ? azapi_resource.database[0].id : "${azurerm_managed_redis.cluster[0].id}/databases/default"
}

output "database_name" {
  description = "The name of the Redis database"
  value       = var.database_name
}

output "hostname" {
  description = "The hostname of the Redis database"
  value       = var.use_azapi ? data.azapi_resource.cluster_data[0].output.properties.hostName : azurerm_managed_redis.cluster[0].hostname
}

output "port" {
  description = "The port of the Redis database"
  value       = var.use_azapi ? 10000 : azurerm_managed_redis.cluster[0].default_database[0].port
}

output "primary_key" {
  description = "The primary access key for the Redis database (null if access keys are disabled)"
  value       = var.access_keys_authentication_enabled ? (var.use_azapi ? data.azapi_resource_action.database_keys[0].output.primaryKey : azurerm_managed_redis.cluster[0].default_database[0].primary_access_key) : null
  sensitive   = true
}

output "secondary_key" {
  description = "The secondary access key for the Redis database (null if access keys are disabled)"
  value       = var.access_keys_authentication_enabled ? (var.use_azapi ? data.azapi_resource_action.database_keys[0].output.secondaryKey : azurerm_managed_redis.cluster[0].default_database[0].secondary_access_key) : null
  sensitive   = true
}

output "connection_string" {
  description = "Redis connection string (null if access keys are disabled)"
  value = var.access_keys_authentication_enabled ? (var.use_azapi ? format(
    "rediss://:%s@%s:10000",
    data.azapi_resource_action.database_keys[0].output.primaryKey,
    data.azapi_resource.cluster_data[0].output.properties.hostName
    ) : format(
    "rediss://:%s@%s:%d",
    azurerm_managed_redis.cluster[0].default_database[0].primary_access_key,
    azurerm_managed_redis.cluster[0].hostname,
    azurerm_managed_redis.cluster[0].default_database[0].port
  )) : null
  sensitive = true
}

output "connection_string_secondary" {
  description = "Redis connection string using secondary key (null if access keys are disabled)"
  value = var.access_keys_authentication_enabled ? (var.use_azapi ? format(
    "rediss://:%s@%s:10000",
    data.azapi_resource_action.database_keys[0].output.secondaryKey,
    data.azapi_resource.cluster_data[0].output.properties.hostName
    ) : format(
    "rediss://:%s@%s:%d",
    azurerm_managed_redis.cluster[0].default_database[0].secondary_access_key,
    azurerm_managed_redis.cluster[0].hostname,
    azurerm_managed_redis.cluster[0].default_database[0].port
  )) : null
  sensitive = true
}

output "resource_group_name" {
  description = "The name of the resource group containing the Redis resources"
  value       = var.resource_group_name
}

output "location" {
  description = "The Azure region of the Redis Enterprise cluster"
  value       = var.location
}

output "sku" {
  description = "The SKU of the Redis Enterprise cluster"
  value       = var.sku
}

output "modules" {
  description = "List of Redis modules enabled on the database"
  value       = var.modules
}

output "high_availability_enabled" {
  description = "Whether high availability is enabled for the cluster"
  value       = var.high_availability
}

output "minimum_tls_version" {
  description = "The minimum TLS version configured for the cluster"
  value       = var.minimum_tls_version
}

output "redis_cli_command" {
  description = "Redis CLI command to connect to the database"
  value = var.use_azapi ? format(
    "redis-cli -h %s -p 10000 -a '<primary_key>'",
    data.azapi_resource.cluster_data[0].output.properties.hostName
    ) : format(
    "redis-cli -h %s -p 10000 -a '<primary_key>'",
    azurerm_managed_redis.cluster[0].hostname
  )
}

output "test_connection_info" {
  description = "Information for testing the Redis connection"
  value = var.use_azapi ? {
    hostname = data.azapi_resource.cluster_data[0].output.properties.hostName
    port     = 10000
    modules  = var.modules
    } : {
    hostname = null
    port     = 10000
    modules  = []
  }
}
