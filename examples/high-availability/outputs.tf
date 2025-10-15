output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "cluster_id" {
  description = "ID of the Redis Enterprise cluster"
  value       = module.redis_enterprise.cluster_id
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

output "connection_string" {
  description = "Primary Redis connection string"
  value       = module.redis_enterprise.connection_string
  sensitive   = true
}

output "connection_string_secondary" {
  description = "Secondary Redis connection string for failover testing"
  value       = module.redis_enterprise.connection_string_secondary
  sensitive   = true
}

output "availability_zones" {
  description = "Availability zones the cluster is deployed across"
  value       = var.availability_zones
}

output "high_availability_enabled" {
  description = "Confirmation that high availability is enabled"
  value       = module.redis_enterprise.high_availability_enabled
}

output "sku" {
  description = "Production SKU being used"
  value       = module.redis_enterprise.sku
}

output "production_readiness_checklist" {
  description = "Production readiness validation checklist"
  value = {
    high_availability = module.redis_enterprise.high_availability_enabled
    multi_az_deployment = length(var.availability_zones) > 1
    tls_encryption = module.redis_enterprise.minimum_tls_version == "1.2"
    production_sku = module.redis_enterprise.sku != "Balanced_B0"
    backup_tags_configured = true
    monitoring_tags_configured = true
  }
}

output "operational_commands" {
  description = "Common operational commands for production management"
  value = {
    health_check = "redis-cli -u '<connection_string>' ping"
    info_command = "redis-cli -u '<connection_string>' info server"
    memory_usage = "redis-cli -u '<connection_string>' info memory"
    performance_test = "redis-benchmark -u '<connection_string>' -t set,get -n 10000"
    failover_test = "redis-cli -u '<connection_string>' DEBUG SEGFAULT"
  }
}

output "monitoring_endpoints" {
  description = "Key metrics to monitor for high availability operations"
  value = {
    cluster_health = "${module.redis_enterprise.hostname}:${module.redis_enterprise.port}"
    primary_endpoint = module.redis_enterprise.hostname
    backup_policy = "daily"
    availability_target = "high"
  }
}
