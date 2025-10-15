# Primary region resource group
resource "azurerm_resource_group" "primary" {
  name     = "rg-${var.project_name}-${var.primary_location}"
  location = var.primary_location
  
  tags = {
    Environment = var.environment
    Region      = "primary"
    Purpose     = "multi-region-redis"
  }
}

# Secondary region resource group
resource "azurerm_resource_group" "secondary" {
  name     = "rg-${var.project_name}-${var.secondary_location}"
  location = var.secondary_location
  
  tags = {
    Environment = var.environment
    Region      = "secondary"
    Purpose     = "multi-region-redis"
  }
}

# Primary Redis Enterprise cluster
module "redis_primary" {
  source = "../../modules/managed-redis"
  
  name                = "${var.project_name}-primary"
  resource_group_name = azurerm_resource_group.primary.name
  location            = azurerm_resource_group.primary.location
  
  sku = var.redis_sku
  
  modules = [
    "RedisJSON",
    "RediSearch"
  ]
  
  high_availability   = true
  minimum_tls_version = "1.2"
  zones              = ["1", "2", "3"]
  
  use_azapi = true
  
  tags = {
    Environment = var.environment
    Region      = "primary"
    Role        = "primary-redis"
    Criticality = "high"
  }
}

# Secondary Redis Enterprise cluster
module "redis_secondary" {
  source = "../../modules/managed-redis"
  
  name                = "${var.project_name}-secondary"
  resource_group_name = azurerm_resource_group.secondary.name
  location            = azurerm_resource_group.secondary.location
  
  sku = var.redis_sku
  
  modules = [
    "RedisJSON",
    "RediSearch"
  ]
  
  high_availability   = true
  minimum_tls_version = "1.2"
  zones              = ["1", "2", "3"]
  
  use_azapi = true
  
  tags = {
    Environment = var.environment
    Region      = "secondary"
    Role        = "secondary-redis"
    Criticality = "high"
  }
}

# Traffic Manager profile for global load balancing (future enhancement)
# Note: This is a placeholder for when Azure Managed Redis supports Traffic Manager integration
/*
resource "azurerm_traffic_manager_profile" "redis" {
  name                = "${var.project_name}-traffic-manager"
  resource_group_name = azurerm_resource_group.primary.name

  traffic_routing_method = "Priority"

  dns_config {
    relative_name = "${var.project_name}-redis"
    ttl          = 100
  }

  monitor_config {
    protocol                    = "TCP"
    port                       = 10000
    path                       = ""
    interval_in_seconds        = 30
    timeout_in_seconds         = 10
    tolerated_number_of_failures = 3
  }

  tags = {
    Environment = var.environment
    Purpose     = "redis-load-balancing"
  }
}
*/
