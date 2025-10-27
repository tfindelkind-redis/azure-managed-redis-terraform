# Virtual Network for Private Connectivity
resource "azurerm_virtual_network" "redis" {
  name                = "vnet-${var.redis_name}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  address_space       = var.vnet_address_space

  tags = var.tags
}

# Subnet for Redis Private Endpoint
resource "azurerm_subnet" "redis" {
  name                 = "snet-redis-pe"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.redis.name
  address_prefixes     = var.redis_subnet_prefix
}

# Private DNS Zone for Redis Enterprise
resource "azurerm_private_dns_zone" "redis" {
  name                = "privatelink.redisenterprise.cache.azure.net"
  resource_group_name = data.azurerm_resource_group.main.name

  tags = var.tags
}

# Link DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "redis" {
  name                  = "redis-dns-link"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.redis.name
  virtual_network_id    = azurerm_virtual_network.redis.id
  registration_enabled  = false

  tags = var.tags
}

# Private Endpoint for Redis Enterprise Cluster
resource "azurerm_private_endpoint" "redis" {
  name                = "pe-${var.redis_name}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.redis.id

  private_service_connection {
    name                           = "psc-${var.redis_name}"
    private_connection_resource_id = azurerm_managed_redis.main.id
    is_manual_connection           = false
    subresource_names              = ["redisEnterprise"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.redis.id]
  }

  tags = var.tags

  depends_on = [azurerm_managed_redis.main]
}
