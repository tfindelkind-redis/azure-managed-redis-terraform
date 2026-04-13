# Provider Support for Azure Managed Redis with EntraID Authentication

This document clarifies the provider support for deploying Azure Managed Redis (Redis Enterprise) with EntraID authentication across different tools.

## 📊 Support Matrix

**Updated: April 2026**

| Component | Terraform azurerm | Terraform AzAPI | Bicep/ARM | Azure CLI |
|-----------|-------------------|-----------------|-----------|-----------|
| **Redis Cluster** | ✅ 4.50.0+ | ✅ Supported | ✅ Supported | ✅ Supported |
| **Redis Database** | ✅ 4.50.0+ | ✅ Supported | ✅ Supported | ✅ Supported |
| **NoCluster Mode** | ✅ 4.50.0+ | ✅ Supported | ✅ Supported | ✅ Supported |
| **RDB/AOF Persistence** | ✅ 4.54.0+ | ✅ Supported | ✅ Supported | ✅ Supported |
| **Access Policy Assignment** | ✅ **4.60.0+** | ✅ Supported | ✅ Supported | ✅ Supported |
| **RBAC Role Assignment** | ✅ Supported | ✅ Supported | ✅ Supported | ✅ Supported |

## 🎯 Key Takeaways

### For Terraform Users

**Full AzureRM Support (v4.60.0+):**
As of February 2026, the AzureRM provider now supports ALL Azure Managed Redis features:
- ✅ `azurerm_managed_redis` (since v4.50.0)
- ✅ NoCluster mode (since v4.50.0)
- ✅ RDB/AOF Persistence (since v4.54.0)
- ✅ `azurerm_managed_redis_access_policy_assignment` (since v4.60.0)

**Complete flexibility - choose either provider:**
- Use `use_azapi = false` for pure azurerm deployment
- Use `use_azapi = true` for azapi (useful for preview API features)

**Historical Note:**
Prior to v4.60.0 (released February 12, 2026), access policy assignments required the AzAPI provider. This limitation has been resolved.

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

- **Redis Cluster/Database**: Using AzAPI (`use_azapi = true`) - can also use azurerm
- **Access Policy Assignment**: Using AzAPI - can also use azurerm (v4.60.0+)
- **RBAC Role Assignment**: Using azurerm

### Can I Switch to azurerm?

**Yes, fully!** You can now switch the entire deployment to azurerm:

```bash
./switch-provider.sh to-azurerm
```

With AzureRM 4.60.0+, you can also use `azurerm_managed_redis_access_policy_assignment` for access policies. See `redis-access-policy.tf` for examples of both approaches.

### Required Providers

With AzureRM 4.60.0+, you can use either provider:

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.60"  # Required for access policy assignments
    }
    azapi = {  # Optional - for preview features or legacy compatibility
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
| `Microsoft.Cache/redisEnterprise` | `azurerm_managed_redis` (v4.50+) | `azapi_resource` | Native |
| `Microsoft.Cache/redisEnterprise/databases` | `azurerm_managed_redis` (inline) | `azapi_resource` | Native |
| `Microsoft.Cache/redisEnterprise/databases/accessPolicyAssignments` | `azurerm_managed_redis_access_policy_assignment` (v4.60+) | `azapi_resource` | Native |

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

## 🔮 Current Status (April 2026)

**All features now supported in AzureRM!**

The `azurerm` provider has caught up with full Azure Managed Redis support:

| Feature | Version Added | Resource |
|---------|---------------|----------|
| Managed Redis (NoCluster) | v4.50.0 (Oct 2025) | `azurerm_managed_redis` |
| RDB/AOF Persistence | v4.54.0 (Nov 2025) | Properties in `azurerm_managed_redis` |
| Access Policy Assignments | v4.60.0 (Feb 2026) | `azurerm_managed_redis_access_policy_assignment` |

Both providers remain valid options:
- **AzureRM**: Recommended for stable production deployments
- **AzAPI**: Useful when you need preview API versions or new features before azurerm support

## ❓ FAQ

**Q: Which provider should I use?**  
A: For new deployments, AzureRM 4.60+ provides native support for all features. Use AzAPI if you need preview API versions.

**Q: How do I migrate from AzAPI to AzureRM for access policies?**  
A: Replace `azapi_resource` with `azurerm_managed_redis_access_policy_assignment`. See `redis-access-policy.tf` for examples.

**Q: Is AzAPI still production-ready?**  
A: Yes! AzAPI is officially maintained by Microsoft and remains production-ready. It's useful for preview features.

**Q: Should I use Bicep instead of Terraform?**  
A: That depends on your requirements. Both now have full feature support for Azure Managed Redis. Choose based on your team's preferences and tooling.

**Q: Will my existing AzAPI code still work?**  
A: Yes! AzAPI configurations continue to work. Migration to azurerm is optional.

## 📖 References

- **AzAPI Provider**: https://registry.terraform.io/providers/Azure/azapi/latest/docs
- **AzureRM Provider**: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- **Bicep AVM Modules**: https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/cache/redis-enterprise
- **Azure Managed Redis Docs**: https://learn.microsoft.com/azure/azure-cache-for-redis/managed-redis/
- **EntraID Authentication**: https://learn.microsoft.com/azure/azure-cache-for-redis/managed-redis/managed-redis-entra-for-authentication
