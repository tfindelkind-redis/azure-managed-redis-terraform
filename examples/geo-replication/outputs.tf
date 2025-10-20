output "primary_resource_group" {
  description = "Primary resource group name"
  value       = azurerm_resource_group.primary.name
}

output "secondary_resource_group" {
  description = "Secondary resource group name"
  value       = azurerm_resource_group.secondary.name
}

output "primary_cluster_id" {
  description = "Primary Redis Enterprise cluster ID"
  value       = module.redis_primary.cluster_id
}

output "secondary_cluster_id" {
  description = "Secondary Redis Enterprise cluster ID"
  value       = azapi_resource.secondary_cluster.id
}

output "primary_hostname" {
  description = "Primary Redis database hostname"
  value       = module.redis_primary.hostname
}

output "secondary_hostname" {
  description = "Secondary Redis database hostname"
  value       = jsondecode(data.azapi_resource.secondary_cluster_data.output).properties.hostName
}

output "primary_connection_string" {
  description = "Primary Redis connection string"
  value       = module.redis_primary.connection_string
  sensitive   = true
}

output "secondary_connection_string" {
  description = "Secondary Redis connection string"
  value = format(
    "rediss://:%s@%s:10000",
    jsondecode(data.azapi_resource_action.secondary_database_keys.output).primaryKey,
    jsondecode(data.azapi_resource.secondary_cluster_data.output).properties.hostName
  )
  sensitive = true
}

output "geo_replication_group_name" {
  description = "Geo-replication group nickname"
  value       = var.geo_replication_group_name
}

output "regions" {
  description = "Deployed regions"
  value = {
    primary   = var.primary_location
    secondary = var.secondary_location
  }
}

output "failover_endpoints" {
  description = "Endpoints for failover configuration"
  value = {
    primary = {
      hostname = module.redis_primary.hostname
      port     = module.redis_primary.port
      region   = var.primary_location
    }
    secondary = {
      hostname = jsondecode(data.azapi_resource.secondary_cluster_data.output).properties.hostName
      port     = 10000
      region   = var.secondary_location
    }
  }
}

output "application_config" {
  description = "Application configuration for geo-replication setup"
  value = {
    primary_endpoint   = "${module.redis_primary.hostname}:${module.redis_primary.port}"
    secondary_endpoint = "${jsondecode(data.azapi_resource.secondary_cluster_data.output).properties.hostName}:10000"
    use_tls            = true
    connection_timeout = "5s"
    read_timeout       = "3s"
    write_timeout      = "3s"
  }
}

output "monitoring_endpoints" {
  description = "Endpoints for monitoring and health checks"
  value = {
    primary = {
      health_check_url = "tcp://${module.redis_primary.hostname}:${module.redis_primary.port}"
      region           = var.primary_location
      cluster_id       = module.redis_primary.cluster_id
    }
    secondary = {
      health_check_url = "tcp://${jsondecode(data.azapi_resource.secondary_cluster_data.output).properties.hostName}:10000"
      region           = var.secondary_location
      cluster_id       = azapi_resource.secondary_cluster.id
    }
  }
}

output "disaster_recovery_info" {
  description = "Information for disaster recovery planning"
  value = {
    primary_region    = var.primary_location
    secondary_region  = var.secondary_location
    sku               = var.redis_sku
    high_availability = true
    backup_policy     = "Configure manual backup procedures"
    rpo_target        = "Use application-level replication for data consistency"
    rto_target        = "DNS failover + application restart time"
  }
}
