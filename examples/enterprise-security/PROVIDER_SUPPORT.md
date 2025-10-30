# Provider Support for Azure Managed Redis with EntraID Authentication

This document clarifies the provider support for deploying Azure Managed Redis (Redis Enterprise) with EntraID authentication across different tools.

## 📊 Support Matrix

| Component | Terraform azurerm | Terraform AzAPI | Bicep/ARM | Azure CLI |
|-----------|-------------------|-----------------|-----------|-----------|
| **Redis Cluster** | ✅ Supported | ✅ Supported | ✅ Supported | ✅ Supported |
| **Redis Database** | ✅ Supported | ✅ Supported | ✅ Supported | ✅ Supported |
| **Access Policy Assignment** | ❌ **NOT Supported** | ✅ **REQUIRED** | ✅ Supported | ✅ Supported |
| **RBAC Role Assignment** | ✅ Supported | ✅ Supported | ✅ Supported | ✅ Supported |

## 🎯 Key Takeaways

### For Terraform Users

**You have flexibility for Redis cluster/database:**
- Choose `use_azapi = true` (recommended) OR
- Choose `use_azapi = false` (using azurerm)

**Access policy assignments are MANDATORY for AzAPI:**
- The `azapi` provider MUST be in your `versions.tf`
- The `redis-access-policy.tf` file ALWAYS uses `azapi_resource`
- This is a Terraform limitation, not an Azure limitation

**Why the limitation?**
The HashiCorp `azurerm` provider (as of v4.x in January 2025) does not include the `Microsoft.Cache/redisEnterprise/databases/accessPolicyAssignments` resource type. The Azure API supports it, but the Terraform provider doesn't expose it yet.

### For Bicep/ARM Users

**No limitations - everything just works!**

All resources are natively supported through standard ARM resource types:

```bicep
// Cluster
resource cluster 'Microsoft.Cache/redisEnterprise@2024-10-01' = { ... }

// Database
resource database 'Microsoft.Cache/redisEnterprise/databases@2024-10-01' = { ... }

// Access Policy Assignment (native support!)
resource accessPolicy 'Microsoft.Cache/redisEnterprise/databases/accessPolicyAssignments@2024-10-01' = {
  parent: database
  name: 'app-managed-identity'
  properties: {
    accessPolicyName: 'default'
    user: {
      objectId: managedIdentity.properties.principalId
    }
  }
}
```

See the [Azure Verified Modules (AVM)](https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/cache/redis-enterprise) for complete Bicep examples.

### For Azure CLI Users

**Full native support:**

```bash
az redisenterprise database access-policy-assignment create \
  --cluster-name <cluster-name> \
  --database-name default \
  --resource-group <rg-name> \
  --access-policy-assignment-name <name> \
  --object-id <principal-id>
```

## 🔧 This Example's Configuration

### Current Setup

- **Redis Cluster/Database**: Using AzAPI (`use_azapi = true`)
- **Access Policy Assignment**: Using AzAPI (required)
- **RBAC Role Assignment**: Using azurerm

### Can I Switch to azurerm?

**Yes, partially!** You can switch the Redis cluster/database to azurerm:

```bash
./switch-provider.sh to-azurerm
```

But the access policy assignment (`redis-access-policy.tf`) will continue to use AzAPI because azurerm doesn't support it.

### Required Providers

Regardless of your choice for Redis resources, your `versions.tf` must include:

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
    azapi = {  # REQUIRED for access policy assignments
      source  = "azure/azapi"
      version = "~> 1.15"
    }
    # ... other providers
  }
}
```

## 📚 Resource Type Reference

### Azure Managed Redis (Enterprise/Managed SKUs)

| Resource Type | Terraform azurerm | Terraform AzAPI | Bicep/ARM |
|---------------|-------------------|-----------------|-----------|
| `Microsoft.Cache/redisEnterprise` | `azurerm_redis_enterprise_cluster` | `azapi_resource` | Native |
| `Microsoft.Cache/redisEnterprise/databases` | `azurerm_redis_enterprise_database` | `azapi_resource` | Native |
| `Microsoft.Cache/redisEnterprise/databases/accessPolicyAssignments` | ❌ Not available | `azapi_resource` | Native |

### Azure Cache for Redis (Classic SKUs)

For comparison, the classic Azure Cache for Redis has full support across all tools:

| Resource Type | Terraform azurerm | Bicep/ARM |
|---------------|-------------------|-----------|
| `Microsoft.Cache/redis` | `azurerm_redis_cache` | Native |
| `Microsoft.Cache/redis/accessPolicyAssignments` | `azurerm_redis_cache_access_policy_assignment` | Native |

## 🆚 API Differences: Managed Redis vs Cache for Redis

When working with access policies, note these critical differences:

| Property | Azure Cache for Redis | Azure Managed Redis |
|----------|----------------------|---------------------|
| **Access Policy Name** | Custom (e.g., "Data Contributor") | Must be `"default"` |
| **Object Structure** | Flat: `objectId` + `objectIdAlias` | Nested: `user { objectId }` |
| **Resource Path** | `/redis/{cache}/accessPolicyAssignments` | `/redisEnterprise/{cluster}/databases/{db}/accessPolicyAssignments` |

## 🔮 Future Outlook

The `azurerm` provider is actively maintained by HashiCorp. It's likely that support for access policy assignments will be added in a future version. When that happens:

1. ✅ You'll be able to use native `azurerm` resources
2. ✅ Existing AzAPI configurations will continue to work
3. ✅ Migration will be straightforward (just update resource type)

For now, AzAPI provides a fully supported workaround that works perfectly with the Azure API.

## ❓ FAQ

**Q: Why can't I use azurerm for access policies?**  
A: The HashiCorp azurerm provider hasn't added this resource type yet. It's a provider limitation, not an Azure limitation.

**Q: Is AzAPI production-ready?**  
A: Yes! AzAPI is officially maintained by Microsoft and is production-ready. It's specifically designed for accessing Azure features before they're available in azurerm.

**Q: Will my code break when azurerm adds support?**  
A: No. You can continue using AzAPI, or migrate to native azurerm resources when available.

**Q: Should I use Bicep instead of Terraform?**  
A: That depends on your requirements. Bicep has native support for all Azure features immediately. Terraform provides cross-cloud capabilities. Both are excellent choices.

**Q: Can I contribute to add this to azurerm?**  
A: Yes! The azurerm provider is open source. You can open an issue or PR: https://github.com/hashicorp/terraform-provider-azurerm

## 📖 References

- **AzAPI Provider**: https://registry.terraform.io/providers/Azure/azapi/latest/docs
- **AzureRM Provider**: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- **Bicep AVM Modules**: https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/cache/redis-enterprise
- **Azure Managed Redis Docs**: https://learn.microsoft.com/azure/azure-cache-for-redis/managed-redis/
- **EntraID Authentication**: https://learn.microsoft.com/azure/azure-cache-for-redis/managed-redis/managed-redis-entra-for-authentication
