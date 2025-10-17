output "resource_group_name" {
  description = "Name of the resource group"
  value       = var.create_resource_group ? azurerm_resource_group.main[0].name : data.azurerm_resource_group.existing[0].name
}

output "cluster_name" {
  description = "Name of the Redis Enterprise cluster"
  value       = module.redis_enterprise.cluster_name
}

output "hostname" {
  description = "Hostname of the Redis database"
  value       = module.redis_enterprise.hostname
}

output "port" {
  description = "Port of the Redis database"
  value       = module.redis_enterprise.port
}

output "enabled_modules" {
  description = "List of enabled Redis modules"
  value       = module.redis_enterprise.modules
}

output "connection_string" {
  description = "Redis connection string"
  value       = module.redis_enterprise.connection_string
  sensitive   = true
}

output "module_test_commands" {
  description = "Example commands to test each enabled module"
  value = {
    redis_json = [
      "JSON.SET user:1 $ '{\"name\":\"John\",\"age\":30}'",
      "JSON.GET user:1 $.name"
    ]
    redis_search = [
      "FT.CREATE users_idx ON JSON PREFIX 1 user: SCHEMA $.name AS name TEXT",
      "FT.SEARCH users_idx '*'"
    ]
    redis_bloom = [
      "BF.RESERVE bf_users 0.01 1000",
      "BF.ADD bf_users user@example.com",
      "BF.EXISTS bf_users user@example.com"
    ]
    redis_timeseries = [
      "TS.CREATE temp:1 RETENTION 3600",
      "TS.ADD temp:1 * 23.5",
      "TS.RANGE temp:1 - +"
    ]
  }
}

output "high_availability_enabled" {
  description = "Whether high availability is enabled"
  value       = module.redis_enterprise.high_availability_enabled
}

output "sku" {
  description = "SKU of the Redis Enterprise cluster"
  value       = module.redis_enterprise.sku
}
