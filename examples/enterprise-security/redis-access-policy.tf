# Redis Enterprise Access Policy for Entra ID Authentication
# Required when accessKeysAuthentication is disabled

# NOTE FOR TERRAFORM USERS:
# The resource type Microsoft.Cache/redisEnterprise/databases/accessPolicyAssignments
# is NOT available in the azurerm provider (as of v4.x - Jan 2025).
# Terraform users MUST use AzAPI provider for access policy assignments.
#
# For Bicep/ARM deployments, you can use the native resource type:
# resource accessPolicy 'Microsoft.Cache/redisEnterprise/databases/accessPolicyAssignments@2024-10-01'
#
# See: https://learn.microsoft.com/en-us/azure/azure-cache-for-redis/managed-redis/managed-redis-entra-for-authentication

# IMPORTANT: For Azure Managed Redis (Enterprise), the access policy structure differs from Azure Cache for Redis:
# - accessPolicyName must be "default" (not "Data Contributor" or other custom names)
# - user is a nested object with objectId property (not flat objectId + objectIdAlias)

# Create access policy assignment for the managed identity using AzAPI
# This resource is REQUIRED for Entra ID authentication to work
resource "azapi_resource" "redis_access_policy" {
  type      = "Microsoft.Cache/redisEnterprise/databases/accessPolicyAssignments@2024-10-01"
  name      = "app-managed-identity"
  parent_id = module.redis_enterprise.database_id
  
  # Must disable schema validation as this resource type is not yet in the AzAPI schema
  schema_validation_enabled = false

  body = jsonencode({
    properties = {
      accessPolicyName = "default" # CRITICAL: Must be "default" for Azure Managed Redis
      user = {
        objectId = azurerm_user_assigned_identity.redis.principal_id
      }
    }
  })

  depends_on = [
    module.redis_enterprise,
    azurerm_user_assigned_identity.redis
  ]
}

