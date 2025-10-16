# Create resource group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    Owner       = var.owner
    Example     = "simple-redis"
  }
}

# Deploy Redis Enterprise cluster using the module
module "redis_enterprise" {
  source = "../../modules/managed-redis"

  name                = var.redis_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  # Basic configuration - minimal cost
  sku               = "Balanced_B0"
  modules           = ["RedisJSON"] # Single module only
  high_availability = false         # Disabled for cost optimization

  # Security settings
  minimum_tls_version = "1.2"
  client_protocol     = "Encrypted"

  # Use AzAPI for now (will switch to native when available)
  use_azapi = true

  tags = {
    Environment = var.environment
    Owner       = var.owner
    Example     = "simple-redis"
    CostCenter  = "development"
  }
}
