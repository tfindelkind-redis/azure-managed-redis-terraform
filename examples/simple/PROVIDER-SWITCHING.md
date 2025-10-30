# Provider Switching Guide

This guide explains how to switch between the AzAPI and AzureRM providers for Azure Managed Redis deployments.

## Overview

The Azure Managed Redis module supports both providers:

- **AzAPI Provider**: Uses the Azure Resource Manager API directly via the AzAPI provider
- **AzureRM Provider**: Uses the native `azurerm_managed_redis` resource (v4.50+)

Both providers manage the same underlying Azure resources and provide identical functionality. You can switch between them without recreating your Redis infrastructure.

## Why Switch Providers?

### Use AzAPI when:
- You need access to preview API features before they're in AzureRM
- You want direct control over Azure ARM API calls
- You're working with cutting-edge Azure features

### Use AzureRM when:
- You prefer native Terraform resources with built-in validation
- You want better IDE/editor support and autocomplete
- You need simpler configuration with less JSON manipulation
- You're following HashiCorp's recommended practices

## Quick Start

### Check Current Provider

```bash
./switch-provider.sh status
```

This will show:
- Current `use_azapi` setting in `main.tf`
- Resources currently in Terraform state
- Which provider is active

### Switch to AzureRM (Recommended)

```bash
./switch-provider.sh to-azurerm
```

This will:
1. ✅ Backup your current state file
2. ✅ Update `main.tf` to set `use_azapi = false`
3. ✅ Remove AzAPI resources from state
4. ✅ Import resources into AzureRM provider
5. ✅ Run a plan to verify no changes

### Switch to AzAPI

```bash
./switch-provider.sh to-azapi
```

This will:
1. ✅ Backup your current state file
2. ✅ Update `main.tf` to set `use_azapi = true`
3. ✅ Remove AzureRM resources from state
4. ✅ Import resources into AzAPI provider
5. ✅ Run a plan to verify no changes

## Detailed Process

### Prerequisites

- Terraform >= 1.3
- Azure CLI authenticated
- Existing deployed Redis resources
- AzureRM provider >= 4.50 (for AzureRM support)
- AzAPI provider >= 1.15 (for AzAPI support)

### Safety Features

The script includes several safety measures:

1. **State Backups**: Automatically creates timestamped backups before any changes
   - Format: `terraform.tfstate.backup-{provider}-{timestamp}`
   - Example: `terraform.tfstate.backup-azapi-20241030-143022`

2. **Confirmation Prompt**: Asks for explicit confirmation before migrating

3. **Validation**: Runs `terraform plan` after migration to verify success

4. **Error Handling**: Stops on errors and provides clear messages

### Step-by-Step Example

#### Switching from AzAPI to AzureRM

```bash
$ ./switch-provider.sh to-azurerm

═══════════════════════════════════════════════════════════
  Migrating from AzAPI to AzureRM
═══════════════════════════════════════════════════════════

ℹ Step 1: Backing up current state...
✓ State backed up

ℹ Step 2: Updating main.tf to use AzureRM...
✓ Updated main.tf to use_azapi = false

ℹ Step 3: Removing AzAPI resources from state...
✓ AzAPI resources removed from state

ℹ Step 4: Importing existing resources into AzureRM provider...
ℹ Importing cluster: /subscriptions/.../redisEnterprise/my-redis
✓ Successfully imported AzureRM resources

ℹ Step 5: Running terraform plan to verify...
✓ Migration from AzAPI to AzureRM completed!
```

#### Switching from AzureRM to AzAPI

```bash
$ ./switch-provider.sh to-azapi

═══════════════════════════════════════════════════════════
  Migrating from AzureRM to AzAPI
═══════════════════════════════════════════════════════════

ℹ Step 1: Backing up current state...
✓ State backed up

ℹ Step 2: Updating main.tf to use AzAPI...
✓ Updated main.tf to use_azapi = true

ℹ Step 3: Removing AzureRM resources from state...
✓ AzureRM resources removed from state

ℹ Step 4: Importing existing resources into AzAPI provider...
ℹ Importing cluster: /subscriptions/.../redisEnterprise/my-redis
ℹ Importing database: /subscriptions/.../redisEnterprise/my-redis/databases/default
✓ Successfully imported AzAPI resources

ℹ Step 5: Running terraform plan to verify...
✓ Migration from AzureRM to AzAPI completed!
```

## Manual Migration (Advanced)

If you prefer to migrate manually, here are the steps:

### Manual: AzAPI → AzureRM

```bash
# 1. Backup state
cp terraform.tfstate terraform.tfstate.backup

# 2. Update main.tf
# Change: use_azapi = true
# To:     use_azapi = false

# 3. Remove AzAPI resources from state
terraform state rm 'module.redis_enterprise.azapi_resource.cluster[0]'
terraform state rm 'module.redis_enterprise.azapi_resource.database[0]'
terraform state rm 'module.redis_enterprise.data.azapi_resource.cluster_data[0]'
terraform state rm 'module.redis_enterprise.data.azapi_resource_action.database_keys[0]'

# 4. Import into AzureRM
CLUSTER_ID=$(terraform output -raw cluster_id)
terraform import 'module.redis_enterprise.azurerm_managed_redis.cluster[0]' "$CLUSTER_ID"

# 5. Verify
terraform plan
```

### Manual: AzureRM → AzAPI

```bash
# 1. Backup state
cp terraform.tfstate terraform.tfstate.backup

# 2. Update main.tf
# Change: use_azapi = false
# To:     use_azapi = true

# 3. Remove AzureRM resources from state
terraform state rm 'module.redis_enterprise.azurerm_managed_redis.cluster[0]'

# 4. Import into AzAPI
CLUSTER_ID=$(terraform output -raw cluster_id)
DATABASE_ID="${CLUSTER_ID}/databases/default"

terraform import 'module.redis_enterprise.azapi_resource.cluster[0]' "$CLUSTER_ID"
terraform import 'module.redis_enterprise.azapi_resource.database[0]' "$DATABASE_ID"

# 5. Verify
terraform plan
```

## Troubleshooting

### Issue: "Could not determine cluster ID"

**Solution**: The script will prompt you to enter the cluster ID manually. Find it using:

```bash
az redis list --query "[].id" -o tsv
```

Or from Azure Portal:
1. Navigate to your Redis resource
2. Go to "Properties"
3. Copy the "Resource ID"

### Issue: Import fails with authentication error

**Solution**: Ensure you're logged in to Azure CLI:

```bash
az login
az account set --subscription "your-subscription-id"
```

### Issue: Plan shows unexpected changes after migration

**Possible causes**:
1. **Different API versions**: AzAPI and AzureRM might use different API versions
2. **Property defaults**: Some properties might have different defaults

**Solution**: Review the changes carefully:
- If they're cosmetic (tags, computed values), it's usually safe to apply
- If they show resource replacements, investigate before applying

### Issue: Script cannot find terraform command

**Solution**: Ensure Terraform is installed and in your PATH:

```bash
terraform version
```

## Rollback

If something goes wrong, you can restore from backup:

```bash
# List available backups
ls -la terraform.tfstate.backup-*

# Restore from backup
cp terraform.tfstate.backup-azapi-20241030-143022 terraform.tfstate

# Verify
terraform plan
```

## Best Practices

1. **Always test in non-production first**: Try the migration in a dev/test environment

2. **Review the plan**: Always review `terraform plan` output before applying

3. **Keep backups**: The script creates backups automatically, but keep them for a while

4. **Document your choice**: Add a comment in `main.tf` explaining why you chose a specific provider

5. **Stay consistent**: Once you choose a provider, stick with it unless you have a good reason to switch

## Provider Comparison

| Feature | AzAPI | AzureRM |
|---------|-------|---------|
| **Stability** | ⭐⭐⭐ Good | ⭐⭐⭐⭐⭐ Excellent |
| **IDE Support** | ⭐⭐ Limited | ⭐⭐⭐⭐⭐ Full |
| **Validation** | ⭐⭐ API-level | ⭐⭐⭐⭐ Terraform-level |
| **Latest Features** | ⭐⭐⭐⭐⭐ Immediate | ⭐⭐⭐ Delayed |
| **Documentation** | ⭐⭐⭐ API docs | ⭐⭐⭐⭐⭐ Terraform docs |
| **Community Support** | ⭐⭐⭐ Growing | ⭐⭐⭐⭐⭐ Extensive |

## FAQ

### Q: Will my Redis data be affected?

**A**: No. The migration only changes how Terraform tracks the resources, not the resources themselves. Your data is safe.

### Q: How long does migration take?

**A**: Usually less than 1 minute. The script only updates Terraform state, it doesn't modify Azure resources.

### Q: Can I switch back and forth?

**A**: Yes! You can switch between providers as many times as needed. Each migration is independent.

### Q: Do I need to destroy and recreate resources?

**A**: No! The migration uses Terraform's import feature to track existing resources without recreating them.

### Q: What if I have multiple Redis clusters?

**A**: This script handles one module at a time. If you have multiple modules, run the script in each directory.

### Q: Does this work with the enterprise-security example?

**A**: The enterprise-security example currently uses direct AzureRM resources (not the module). This script is designed for examples using the `modules/managed-redis` module.

## Additional Resources

- [AzureRM Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [AzAPI Provider Documentation](https://registry.terraform.io/providers/Azure/azapi/latest/docs)
- [Azure Managed Redis Documentation](https://learn.microsoft.com/azure/redis/managed-redis/managed-redis-overview)
- [Terraform State Management](https://developer.hashicorp.com/terraform/language/state)

## Support

If you encounter issues:

1. Check the [Troubleshooting](#troubleshooting) section above
2. Review your state backups
3. Open an issue in the repository with:
   - Output from `./switch-provider.sh status`
   - Error messages
   - Terraform version
   - Provider versions
