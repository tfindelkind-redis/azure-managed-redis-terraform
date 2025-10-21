# Create resource group (conditional)
resource "azurerm_resource_group" "main" {
  count = var.create_resource_group ? 1 : 0

  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    Owner       = var.owner
    Example     = "simple-redis"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Get existing resource group (conditional)
data "azurerm_resource_group" "existing" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

# Deploy Redis Enterprise cluster using the module
module "redis_enterprise" {
  source = "../../modules/managed-redis"

  name                = var.redis_name
  resource_group_name = var.create_resource_group ? azurerm_resource_group.main[0].name : data.azurerm_resource_group.existing[0].name
  location            = var.create_resource_group ? azurerm_resource_group.main[0].location : data.azurerm_resource_group.existing[0].location

  # Basic configuration - minimal cost
  sku               = "Balanced_B0"
  modules           = []    # No modules for simplicity
  high_availability = false # Disabled for cost optimization

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
