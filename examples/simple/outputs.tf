output "resource_group_name" {
  description = "Name of the resource group containing the Redis resources"
  value       = var.create_resource_group ? azurerm_resource_group.main[0].name : data.azurerm_resource_group.existing[0].name
}

output "cluster_id" {
  description = "ID of the Redis Enterprise cluster"
  value       = module.redis_enterprise.cluster_id
}

output "cluster_name" {
  description = "Name of the Redis Enterprise cluster"
  value       = module.redis_enterprise.cluster_name
}

output "database_id" {
  description = "ID of the Redis database"
  value       = module.redis_enterprise.database_id
}

output "hostname" {
  description = "Hostname of the Redis database"
  value       = module.redis_enterprise.hostname
}

output "port" {
  description = "Port of the Redis database"
  value       = module.redis_enterprise.port
}

output "connection_string" {
  description = "Redis connection string"
  value       = module.redis_enterprise.connection_string
  sensitive   = true
}

output "primary_key" {
  description = "Primary access key for the Redis database"
  value       = module.redis_enterprise.primary_key
  sensitive   = true
}

output "secondary_key" {
  description = "Secondary access key for the Redis database"
  value       = module.redis_enterprise.secondary_key
  sensitive   = true
}

# Helper outputs for testing
output "redis_cli_command" {
  description = "Redis CLI command to connect to the database"
  value       = "redis-cli -h ${module.redis_enterprise.hostname} -p ${module.redis_enterprise.port} -a '<primary_key>'"
}

output "test_connection_info" {
  description = "Information for testing the Redis connection"
  value = {
    hostname = module.redis_enterprise.hostname
    port     = module.redis_enterprise.port
    modules  = module.redis_enterprise.modules
  }
}
