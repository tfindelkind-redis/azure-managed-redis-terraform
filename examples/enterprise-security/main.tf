# Use existing Resource Group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}
