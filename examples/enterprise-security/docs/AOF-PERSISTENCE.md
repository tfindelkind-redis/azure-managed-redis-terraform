# AOF Persistence Configuration for Azure Managed Redis

## Current Status (azurerm v4.50)

### ✅ High Availability
**Status**: Fully supported in Terraform  
**Configuration**: 
```hcl
resource "azurerm_managed_redis" "main" {
  # ... other settings ...
  
  high_availability_enabled = true  # ← Supported!
}
```

### ❌ AOF Persistence  
**Status**: NOT YET supported in azurerm provider (as of v4.50.0)  
**Reason**: The Azure ARM API supports AOF, but the Terraform provider hasn't exposed it yet

## Evidence

From the provider source code:
```go
// Persistence is currently preview and does not return from the RP 
// but will be fully supported in the near future
```

## Workarounds for AOF Persistence

Since AOF persistence is not available in the azurerm provider, you have these options:

### Option 1: Azure CLI Post-Deployment (Recommended)

After deploying with Terraform, configure AOF via Azure CLI:

```bash
# After terraform apply
az redisenterprise database update \
  --cluster-name "my-redis-cluster" \
  --resource-group "my-rg" \
  --name "default" \
  --persistence aof-enabled=true aof-frequency=1s
```

**Add to deployment script:**
```bash
# In deploy-modular.sh after Redis deployment:
REDIS_NAME=$(terraform output -raw cluster_name)
RG_NAME=$(terraform output -raw resource_group_name)

echo "Configuring AOF persistence..."
az redisenterprise database update \
  --cluster-name "$REDIS_NAME" \
  --resource-group "$RG_NAME" \
  --name "default" \
  --persistence aof-enabled=true aof-frequency=1s
```

### Option 2: Azure Portal (Manual)

1. Navigate to your Redis Enterprise instance
2. Go to **Advanced settings**
3. Under **Data Persistence**, select **AOF**
4. Choose **1 second** frequency
5. Click **Save**

### Option 3: Wait for Provider Update

Monitor the azurerm provider releases for AOF support:
- GitHub: https://github.com/hashicorp/terraform-provider-azurerm
- Changelog: https://github.com/hashicorp/terraform-provider-azurerm/blob/main/CHANGELOG.md

## Current Configuration (redis.tf)

```hcl
resource "azurerm_managed_redis" "main" {
  name                = var.redis_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  sku_name            = var.sku_name

  # ✅ HIGH AVAILABILITY - Fully supported
  high_availability_enabled = true

  # Managed Identity Assignment
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.redis.id,
      azurerm_user_assigned_identity.keyvault.id
    ]
  }

  # Customer Managed Key Encryption
  customer_managed_key {
    key_vault_key_id          = azurerm_key_vault_key.redis.id
    user_assigned_identity_id = azurerm_user_assigned_identity.keyvault.id
  }

  # Default Database Configuration
  default_database {
    client_protocol   = "Encrypted"
    clustering_policy = "EnterpriseCluster"
    eviction_policy   = "NoEviction"

    # ❌ AOF PERSISTENCE - Not yet supported in provider
    # Will need to be configured via Azure CLI or Portal
    # after deployment

    dynamic "module" {
      for_each = var.enable_modules ? ["RedisJSON", "RediSearch"] : []
      content {
        name = module.value
      }
    }
  }

  tags = var.tags
}
```

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
