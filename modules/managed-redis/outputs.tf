output "cluster_id" {
  description = "The ID of the Redis Enterprise cluster"
  value       = var.use_azapi ? azapi_resource.cluster[0].id : null
}

output "cluster_name" {
  description = "The name of the Redis Enterprise cluster"
  value       = var.name
}

output "database_id" {
  description = "The ID of the Redis database"
  value       = var.use_azapi ? azapi_resource.database[0].id : null
}

output "database_name" {
  description = "The name of the Redis database"
  value       = var.database_name
}

output "hostname" {
  description = "The hostname of the Redis database"
  value       = var.use_azapi ? jsondecode(data.azapi_resource.cluster_data[0].output).properties.hostName : null
}

output "port" {
  description = "The port of the Redis database"
  value       = 10000
}

output "primary_key" {
  description = "The primary access key for the Redis database"
  value       = var.use_azapi ? jsondecode(data.azapi_resource_action.database_keys[0].output).primaryKey : null
  sensitive   = true
}

output "secondary_key" {
  description = "The secondary access key for the Redis database"
  value       = var.use_azapi ? jsondecode(data.azapi_resource_action.database_keys[0].output).secondaryKey : null
  sensitive   = true
}

output "connection_string" {
  description = "Redis connection string"
  value = var.use_azapi ? format(
    "rediss://:%s@%s:10000",
    jsondecode(data.azapi_resource_action.database_keys[0].output).primaryKey,
    jsondecode(data.azapi_resource.cluster_data[0].output).properties.hostName
  ) : null
  sensitive = true
}

output "connection_string_secondary" {
  description = "Redis connection string using secondary key"
  value = var.use_azapi ? format(
    "rediss://:%s@%s:10000",
    jsondecode(data.azapi_resource_action.database_keys[0].output).secondaryKey,
    jsondecode(data.azapi_resource.cluster_data[0].output).properties.hostName
  ) : null
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
    jsondecode(data.azapi_resource.cluster_data[0].output).properties.hostName
  ) : null
}

output "test_connection_info" {
  description = "Information for testing the Redis connection"
  value = var.use_azapi ? {
    hostname = jsondecode(data.azapi_resource.cluster_data[0].output).properties.hostName
    port     = 10000
    modules  = var.modules
    } : {
    hostname = null
    port     = 10000
    modules  = []
  }
}
