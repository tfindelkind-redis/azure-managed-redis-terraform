# AOF Persistence Configuration for Azure Managed Redis

## Current Status (April 2026)

### ✅ All Persistence Features Now Supported in AzureRM

**As of AzureRM v4.54.0 (November 2025)**, both RDB and AOF persistence are fully supported:

| Feature | AzureRM Version | Status |
|---------|-----------------|--------|
| High Availability | v4.50.0+ | ✅ Supported |
| RDB Persistence | v4.54.0+ | ✅ Supported |
| AOF Persistence | v4.54.0+ | ✅ Supported |

## Configuration Examples

### AzureRM Provider (v4.54.0+)

```hcl
resource "azurerm_managed_redis" "main" {
  name                = var.redis_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  sku_name            = var.sku_name

  high_availability_enabled = true

  default_database {
    client_protocol   = "Encrypted"
    clustering_policy = "EnterpriseCluster"
    eviction_policy   = "NoEviction"

    # ✅ AOF Persistence - Supported since v4.54.0
    persistence_append_only_file_backup_frequency = "1s"

    # ✅ RDB Persistence - Also supported
    persistence_redis_database_backup_frequency = "12h"
  }

  tags = var.tags
}
```

### AzAPI Provider (Alternative)

```hcl
resource "azapi_resource" "redis" {
  type      = "Microsoft.Cache/redisEnterprise@2024-10-01"
  name      = var.redis_name
  parent_id = azurerm_resource_group.main.id
  location  = var.location

  body = {
    sku = {
      name     = var.sku_name
      capacity = 2
    }
    properties = {
      highAvailability = "Enabled"
    }
  }
}

resource "azapi_resource" "redis_database" {
  type      = "Microsoft.Cache/redisEnterprise/databases@2024-10-01"
  name      = "default"
  parent_id = azapi_resource.redis.id

  body = {
    properties = {
      clientProtocol   = "Encrypted"
      clusteringPolicy = "EnterpriseCluster"
      evictionPolicy   = "NoEviction"
      persistence = {
        aofEnabled       = true
        aofFrequency     = "1s"
        rdbEnabled       = true
        rdbFrequency     = "12h"
      }
    }
  }
}
```

## AOF vs RDB Comparison

| Aspect | AOF (Append-Only File) | RDB (Snapshots) |
|--------|------------------------|-----------------|
| **Durability** | Highest (logs every write) | Lower (periodic snapshots) |
| **Performance Impact** | Higher I/O overhead | Lower overhead |
| **Recovery Speed** | Slower (replays log) | Faster (loads snapshot) |
| **Best For** | Maximum data safety | Faster restarts, backups |

## Recommended Configuration

For production workloads requiring durability, use **both** persistence methods:

```hcl
default_database {
  persistence_append_only_file_backup_frequency = "1s"   # AOF for durability
  persistence_redis_database_backup_frequency   = "12h"  # RDB for faster restarts
}
```

## Migration from Workarounds

If you previously used Azure CLI or Portal to configure persistence as a workaround, you can now manage it directly in Terraform:

1. Update your `azurerm` provider to `>= 4.54.0`
2. Add the persistence properties to your `default_database` block
3. Run `terraform plan` to verify changes
4. Run `terraform apply` to update the state

## References

- [AzureRM 4.54.0 Release Notes](https://github.com/hashicorp/terraform-provider-azurerm/releases/tag/v4.54.0)
- [Azure Managed Redis Documentation](https://learn.microsoft.com/azure/azure-cache-for-redis/managed-redis/)

## Recommended Approach

For this enterprise security example:

1. ✅ **Deploy infrastructure with Terraform** (HA enabled)
2. ✅ **Configure AOF via Azure CLI** post-deployment
3. 📝 **Document the manual step** in deployment instructions

This keeps your infrastructure as code while working around the provider limitation.

## Future: When AOF Support is Added

When the provider adds AOF support, the configuration will likely look like:

```hcl
# FUTURE - Not yet supported
default_database {
  client_protocol   = "Encrypted"
  clustering_policy = "EnterpriseCluster"
  eviction_policy   = "NoEviction"
  
  persistence {
    aof_enabled   = true
    aof_frequency = "1s"  # Options: "1s" or "always"
  }
}
```

## References

- Azure Documentation: [Configure data persistence](https://learn.microsoft.com/en-us/azure/redis/how-to-persistence)
- Provider Issue Tracker: https://github.com/hashicorp/terraform-provider-azurerm/issues
- Azure CLI Reference: [az redisenterprise database](https://learn.microsoft.com/en-us/cli/azure/redisenterprise/database)
