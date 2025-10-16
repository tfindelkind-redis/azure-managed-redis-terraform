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
  value       = module.redis_secondary.cluster_id
}

output "primary_hostname" {
  description = "Primary Redis database hostname"
  value       = module.redis_primary.hostname
}

output "secondary_hostname" {
  description = "Secondary Redis database hostname"
  value       = module.redis_secondary.hostname
}

output "primary_connection_string" {
  description = "Primary Redis connection string"
  value       = module.redis_primary.connection_string
  sensitive   = true
}

output "secondary_connection_string" {
  description = "Secondary Redis connection string"
  value       = module.redis_secondary.connection_string
  sensitive   = true
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
      hostname = module.redis_secondary.hostname
      port     = module.redis_secondary.port
      region   = var.secondary_location
    }
  }
}

output "application_config" {
  description = "Application configuration for multi-region setup"
  value = {
    primary_endpoint   = "${module.redis_primary.hostname}:${module.redis_primary.port}"
    secondary_endpoint = "${module.redis_secondary.hostname}:${module.redis_secondary.port}"
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
      health_check_url = "tcp://${module.redis_secondary.hostname}:${module.redis_secondary.port}"
      region           = var.secondary_location
      cluster_id       = module.redis_secondary.cluster_id
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
