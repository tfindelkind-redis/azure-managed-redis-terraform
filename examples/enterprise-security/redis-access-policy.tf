# Redis Enterprise Access Policy for Entra ID Authentication
# Required when accessKeysAuthentication is disabled

# ==============================================================================
# PROVIDER SUPPORT (Updated April 2026)
# ==============================================================================
# As of AzureRM 4.60.0 (February 2026), you can now use EITHER provider:
#
# Option 1: AzureRM (Recommended for new deployments)
#   - Resource: azurerm_managed_redis_access_policy_assignment
#   - Available since: AzureRM 4.60.0 (February 12, 2026)
#   - Stable and fully supported
#
# Option 2: AzAPI (For older environments or preview features)
#   - Resource: azapi_resource with type accessPolicyAssignments
#   - Always available, supports preview API versions
#
# For Bicep/ARM deployments, use the native resource type:
# resource accessPolicy 'Microsoft.Cache/redisEnterprise/databases/accessPolicyAssignments@2024-10-01'
#
# See: https://learn.microsoft.com/en-us/azure/azure-cache-for-redis/managed-redis/managed-redis-entra-for-authentication
# ==============================================================================

# IMPORTANT: For Azure Managed Redis (Enterprise), the access policy structure differs from Azure Cache for Redis:
# - accessPolicyName must be "default" (not "Data Contributor" or other custom names)
# - user is a nested object with objectId property (not flat objectId + objectIdAlias)

# ==============================================================================
# Option 1: AzureRM Provider (Recommended - AzureRM 4.60+)
# ==============================================================================
# Uncomment this block if using AzureRM 4.60+ and use_azapi = false
#
# resource "azurerm_managed_redis_access_policy_assignment" "app_identity" {
#   managed_redis_id = module.redis_enterprise.cluster_id
#   object_id        = azurerm_user_assigned_identity.redis.principal_id
# }

# ==============================================================================
# Option 2: AzAPI Provider (Current default - works with all versions)
# ==============================================================================
# Create access policy assignment for the managed identity using AzAPI
# This resource is REQUIRED for Entra ID authentication to work
resource "azapi_resource" "redis_access_policy" {
  type      = "Microsoft.Cache/redisEnterprise/databases/accessPolicyAssignments@2024-10-01"
  name      = "app-managed-identity"
  parent_id = module.redis_enterprise.database_id

  # Must disable schema validation as this resource type is not yet in the AzAPI schema
  schema_validation_enabled = false

  body = {
    properties = {
      accessPolicyName = "default" # CRITICAL: Must be "default" for Azure Managed Redis
      user = {
        objectId = azurerm_user_assigned_identity.redis.principal_id
      }
    }
  }

  depends_on = [
    module.redis_enterprise,
    azurerm_user_assigned_identity.redis
  ]
}

