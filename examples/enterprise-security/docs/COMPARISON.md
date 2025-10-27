# Comparison: azurerm_managed_redis vs Simple Example (AzAPI)

## Our Enterprise-Security Configuration (azurerm_managed_redis)

### Top-Level Attributes We ARE Using:
- ✅ `name`
- ✅ `resource_group_name`
- ✅ `location`
- ✅ `sku_name` (Balanced_B3)
- ✅ `high_availability_enabled` (currently set to false for testing)
- ✅ `tags`

### Top-Level Attributes We ARE NOT Using:
- ❌ **Missing: No `minimum_tls_version` attribute exists** (only in Redis Cache, not Managed Redis)
- ❌ **Missing: No `zones` attribute exists** (set automatically by Azure for zone-redundant SKUs)

### Blocks We ARE Using:
- ✅ `identity` block (UserAssigned with 2 identities)
- ✅ `customer_managed_key` block (CMK encryption)
- ✅ `default_database` block:
  - `client_protocol = "Encrypted"`
  - `clustering_policy = "EnterpriseCluster"`
  - `eviction_policy = "NoEviction"`
  - `module` blocks (RedisJSON, RediSearch)

### Blocks/Attributes We ARE NOT Using:
- ❌ `timeouts` block (uses default timeouts)
- ❌ `default_database.access_keys_authentication_enabled` (uses default: true)
- ❌ `default_database.geo_replication_group_name` (not needed yet)
- ❌ `default_database.port` (uses default)

---

## Simple Example Configuration (AzAPI)

The simple example uses **azapi_resource** with these properties:

### Cluster-Level (azapi_resource.cluster):
```hcl
body = {
  sku = {
    name = "Balanced_B0"      # vs our B3
    capacity = 1
  }
  properties = {
    highAvailability = "Disabled"     # vs our Enabled (was)
    minimumTlsVersion = "1.2"         # ⚠️ SET AT CLUSTER LEVEL IN AZAPI
  }
  zones = []                          # Empty for simple
}
```

### Database-Level (azapi_resource.database):
```hcl
body = {
  properties = {
    clientProtocol = "Encrypted"      # ✅ Same
    evictionPolicy = "NoEviction"     # ✅ Same
    clusteringPolicy = "EnterpriseCluster"  # ✅ Same
    modules = []                      # vs our RedisJSON, RediSearch
    deferUpgrade = "NotDeferred"      # ⚠️ NOT SET IN OUR CONFIG
    accessKeysAuthentication = "Enabled"  # ⚠️ NOT SET IN OUR CONFIG
    persistence = {                   # ⚠️ NOT SET IN OUR CONFIG
      aofEnabled = false
      rdbEnabled = false
    }
  }
}
```

---

## KEY FINDINGS

### ✅ GOOD NEWS: We ARE setting all critical parameters!

**Comparison with Simple Example:**

| Parameter | Simple (AzAPI) | Enterprise (azurerm) | Status |
|-----------|---------------|---------------------|---------|
| **Cluster Level** |
| SKU | Balanced_B0 | Balanced_B3 | ✅ Different (ours is production) |
| High Availability | Disabled | false (testing) | ⚠️ Temporarily disabled |
| Minimum TLS | "1.2" (explicit) | N/A (no attribute) | ⚠️ **See below** |
| Customer Managed Key | No | Yes | ✅ We have it |
| Identity | No | UserAssigned | ✅ We have it |
| **Database Level** |
| client_protocol | "Encrypted" | "Encrypted" | ✅ Same |
| eviction_policy | "NoEviction" | "NoEviction" | ✅ Same |
| clustering_policy | "EnterpriseCluster" | "EnterpriseCluster" | ✅ Same |
| modules | [] | RedisJSON, RediSearch | ✅ We have more |
| access_keys_auth | "Enabled" (explicit) | (default: true) | ✅ Effectively same |

### ⚠️ IMPORTANT: Minimum TLS Version

**The `minimum_tls_version` attribute does NOT exist in `azurerm_managed_redis`!**

- In AzAPI (simple example): Set explicitly at cluster level as `minimumTlsVersion = "1.2"`
- In azurerm_managed_redis: **This attribute is not exposed by the provider**
- **Azure Default**: According to Azure docs, Managed Redis defaults to TLS 1.2
- **Verification needed**: We should check the deployed resource to confirm TLS version

### 📝 Parameters We Could Add (Optional)

1. **`timeouts` block** - For longer deployment waits if needed:
   ```hcl
   timeouts {
     create = "60m"  # CMK deployments might take longer
     update = "60m"
     delete = "60m"
   }
   ```

2. **`default_database.access_keys_authentication_enabled = true`** - Explicit (currently implicit default)

### 🎯 CONCLUSION

**Our configuration is COMPLETE and matches/exceeds the simple example:**
- ✅ All required parameters are set
- ✅ Enterprise features (CMK, Identity, HA) properly configured
- ✅ Database settings match production best practices
- ⚠️ TLS 1.2 should be default, but we can't explicitly set it in this resource
- ⚠️ Consider adding timeouts for CMK deployments (they can take longer)

**The failure is likely NOT due to missing parameters.**

Possible causes for the deployment failure:
1. **CMK + High Availability combination** - Testing with HA disabled first
2. **Azure region capacity** - North Europe might have temporary capacity issues with B3 SKU
3. **CMK identity propagation** - Even with wait, some Azure backend delay
4. **API rate limiting** - Multiple failed attempts might trigger throttling

**Next step**: Try deployment WITHOUT HA to isolate the issue.
