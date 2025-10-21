RESOURCE_GROUP_PROTECTION# Resource Group Protection

## Overview

All resource groups in this Terraform configuration are protected from accidental deletion using Terraform's `prevent_destroy` lifecycle rule.

## What This Means

When you try to run `terraform destroy` or any operation that would delete a resource group, Terraform will **BLOCK** the operation and show an error like:

```
Error: Instance cannot be destroyed

  on main.tf line 2:
   2: resource "azurerm_resource_group" "main" {

Resource azurerm_resource_group.main has lifecycle.prevent_destroy set, but
the plan calls for this resource to be destroyed. To avoid this error and
continue with the plan, either disable lifecycle.prevent_destroy or reduce
the scope of the plan using the -target flag.
```

## Protected Resource Groups

All resource groups in these examples are protected:

### 1. Simple Example (`examples/simple/main.tf`)
```hcl
resource "azurerm_resource_group" "main" {
  count = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  
  lifecycle {
    prevent_destroy = true  # ✅ PROTECTED
  }
}
```

### 2. High-Availability Example (`examples/high-availability/main.tf`)
```hcl
resource "azurerm_resource_group" "main" {
  count = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  
  lifecycle {
    prevent_destroy = true  # ✅ PROTECTED
  }
}
```

### 3. With-Modules Example (`examples/with-modules/main.tf`)
```hcl
resource "azurerm_resource_group" "main" {
  count = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  
  lifecycle {
    prevent_destroy = true  # ✅ PROTECTED
  }
}
```

### 4. Geo-Replication Example (`examples/geo-replication/main.tf`)
```hcl
# Primary region
resource "azurerm_resource_group" "primary" {
  count    = var.create_resource_groups ? 1 : 0
  name     = var.primary_resource_group_name
  location = var.primary_location
  
  lifecycle {
    prevent_destroy = true  # ✅ PROTECTED
  }
}

# Secondary region
resource "azurerm_resource_group" "secondary" {
  count    = var.create_resource_groups ? 1 : 0
  name     = var.secondary_resource_group_name
  location = var.secondary_location
  
  lifecycle {
    prevent_destroy = true  # ✅ PROTECTED
  }
}
```

## How to Delete a Resource Group (If Really Needed)

If you **absolutely must** delete a resource group, you have three options:

### Option 1: Use Azure CLI (Recommended)
The safest way is to delete the resource group directly in Azure:

```bash
# Delete via Azure CLI
az group delete --name rg-azure-managed-redis-terraform --yes --no-wait

# Remove from Terraform state (so Terraform doesn't try to recreate it)
terraform state rm 'azurerm_resource_group.main[0]'
```

### Option 2: Use Azure Portal
1. Log into Azure Portal
2. Navigate to Resource Groups
3. Select the resource group
4. Click "Delete resource group"
5. Remove from Terraform state:
   ```bash
   terraform state rm 'azurerm_resource_group.main[0]'
   ```

### Option 3: Temporarily Remove Protection (NOT Recommended)
If you must use Terraform to delete:

1. **Comment out** the lifecycle block:
   ```hcl
   resource "azurerm_resource_group" "main" {
     name     = var.resource_group_name
     location = var.location
     
     # lifecycle {
     #   prevent_destroy = true
     # }
   }
   ```

2. Run `terraform apply` to update the state

3. Run `terraform destroy`

4. **IMPORTANT**: Restore the lifecycle block before committing!

## Why This Protection Exists

Resource groups in Azure often contain critical resources beyond what Terraform manages:

- 🔐 **Secrets and Keys** - Managed identities, service principals
- 📊 **Monitoring Data** - Log Analytics workspaces, Application Insights
- 🔗 **Network Resources** - VNets, private endpoints, DNS zones
- 💾 **Data Storage** - Storage accounts with backups or logs
- 👥 **Access Control** - RBAC role assignments

Accidentally deleting a resource group can cause:
- ❌ Data loss
- ❌ Service outages
- ❌ Security incidents
- ❌ Loss of audit trails
- ❌ Broken dependencies in other applications

## Testing and CI/CD

For testing environments where you DO want to clean up:

### GitHub Actions Workflows
Our workflows use `create_resource_group = false` to use existing resource groups, so the lifecycle protection doesn't block cleanup of Redis resources:

```yaml
# terraform.tfvars in workflows
resource_group_name = "rg-azure-managed-redis-terraform"
create_resource_group = false  # Uses existing RG, doesn't manage its lifecycle
```

When `create_resource_group = false`:
- ✅ Resource group is referenced via `data` source (read-only)
- ✅ Redis resources can be destroyed freely
- ✅ Resource group remains intact
- ✅ No lifecycle conflicts

### Local Testing
Use the same approach for local testing:

```hcl
# terraform.tfvars
create_resource_group = false
resource_group_name = "rg-azure-managed-redis-terraform"
```

Then you can safely destroy just the Redis resources:
```bash
terraform destroy  # Only destroys Redis, not the RG
```

## Best Practices

### ✅ DO:
- Use existing resource groups (`create_resource_group = false`)
- Delete individual resources instead of entire resource groups
- Use Azure CLI/Portal for resource group deletion
- Document why you're deleting a resource group
- Check with team members before deleting shared resource groups

### ❌ DON'T:
- Remove lifecycle protection without team approval
- Delete production resource groups without proper change management
- Commit code with lifecycle protection removed
- Use `terraform destroy` on production environments

## Additional Safety Measures

Beyond `prevent_destroy`, consider:

1. **Resource Locks** (Azure-native):
   ```bash
   az lock create --name DoNotDelete \
     --resource-group rg-azure-managed-redis-terraform \
     --lock-type CanNotDelete
   ```

2. **RBAC Permissions**:
   - Limit who can delete resource groups
   - Require elevated permissions for destructive operations

3. **Backup and Recovery**:
   - Regular backups of critical data
   - Document recovery procedures
   - Test restore processes

4. **Change Management**:
   - Require approvals for destructive operations
   - Document all deletions
   - Use separate subscriptions for production/testing

## References

- [Terraform Lifecycle Meta-Arguments](https://www.terraform.io/language/meta-arguments/lifecycle)
- [Azure Resource Locks](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/lock-resources)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

---

**Last Updated**: October 21, 2025  
**Status**: ✅ All resource groups protected
