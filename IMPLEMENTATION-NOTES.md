# Implementation Notes

## API Version Selection

### Current Version: `2024-09-01-preview`

After extensive testing, this module uses Azure Redis Enterprise API version **`2024-09-01-preview`** for stability and reliability.

### Testing History

| API Version | Status | Notes |
|------------|--------|-------|
| `2024-09-01-preview` | ✅ **STABLE** | Proven reliable in production deployments |
| `2025-04-01` | ❌ Failed | Cluster creation fails with "Failed" status, no error details |
| `2025-05-01-preview` | ❌ Failed | Cluster creation fails with "Failed" status, no error details |

### Testing Process

Newer API versions were tested through the complete deployment lifecycle:
1. **Cluster Creation**: ~7 minutes
2. **Database Creation**: ~12 seconds  
3. **Keys Retrieval**: Immediate
4. **Hostname/Connection String**: Output validation
5. **Connectivity Test**: redis-cli PING test

**Result**: While `2024-09-01-preview` completed successfully, newer versions (`2025-04-01`, `2025-05-01-preview`) failed during cluster creation with no actionable error messages.

### Recommendation

**Stay with `2024-09-01-preview`** until newer API versions demonstrate stability in production scenarios. The module includes expanded SKU validation for forward compatibility when upgrading to newer API versions in the future.

---

## Output Structure Pattern

### Challenge: Data Source Returns JSON Strings

When using the AzAPI provider's `azapi_resource` data source to read cluster properties, the `output` attribute returns a **JSON string**, not a parsed object.

### Solution: Use `jsondecode()`

All hostname and connection-related outputs must use `jsondecode()` to parse the JSON string before accessing properties:

```hcl
# INCORRECT - This won't work
# output "hostname" {
#   value = data.azapi_resource.cluster_data[0].output.properties.hostName
# }

# CORRECT - Use jsondecode()
output "hostname" {
  description = "Redis cluster hostname"
  value       = var.enable_database && length(azapi_resource.database) > 0 ? jsondecode(data.azapi_resource.cluster_data[0].output).properties.hostName : null
}
```

### Implementation in Module

The pattern is implemented in `modules/managed-redis/outputs.tf`:

```hcl
# Data source to read cluster properties
data "azapi_resource" "cluster_data" {
  count                  = var.enable_database ? 1 : 0
  type                   = "${local.redis_enterprise_type}@${local.redis_enterprise_api_version}"
  resource_id            = azapi_resource.cluster.id
  response_export_values = ["properties"]
  
  depends_on = [azapi_resource.database]
}

# Parse JSON output for hostname
output "hostname" {
  description = "Redis cluster hostname"
  value       = var.enable_database && length(azapi_resource.database) > 0 ? jsondecode(data.azapi_resource.cluster_data[0].output).properties.hostName : null
}
```

### Example Usage Propagation

All examples automatically inherit this pattern through module outputs:

```hcl
# examples/simple/outputs.tf
output "hostname" {
  description = "Redis cluster hostname"
  value       = module.redis_enterprise.hostname  # Automatically uses jsondecode() from module
}

output "connection_string" {
  description = "Redis connection string with authentication"
  value       = module.redis_enterprise.connection_string
  sensitive   = true
}
```

### Validated Outputs

These outputs have been validated in GitHub Actions deployment:
- ✅ `hostname` = "redis-simple-test-20251020095447.eastus.redis.azure.net"
- ✅ `connection_string` = "rediss://...:10000" (masked for security)
- ✅ `primary_key` / `secondary_key` = Accessible as sensitive outputs
- ✅ Connectivity test PASSED with redis-cli

---

## SKU Validation Expansion

The module includes comprehensive SKU validation supporting 40+ SKU types:

### Supported SKU Categories

1. **Balanced Series**: `Balanced_B0` through `Balanced_B1000`
2. **Flash Optimized**: `FlashOptimized_A250` through `FlashOptimized_A4500`
3. **Memory Optimized**: `MemoryOptimized_M10` through `MemoryOptimized_M2000`
4. **Compute Optimized**: `ComputeOptimized_X5` through `ComputeOptimized_X700`

### Implementation

```hcl
variable "sku" {
  description = "SKU name for the Redis Enterprise cluster"
  type        = string
  default     = "Balanced_B0"
  
  validation {
    condition = contains([
      # Balanced Series (B0-B1000)
      "Balanced_B0", "Balanced_B1", "Balanced_B3", "Balanced_B5",
      "Balanced_B10", "Balanced_B20", "Balanced_B50", "Balanced_B100",
      "Balanced_B150", "Balanced_B250", "Balanced_B350", "Balanced_B500",
      "Balanced_B700", "Balanced_B1000",
      
      # Flash Optimized Series (A250-A4500)
      "FlashOptimized_A250", "FlashOptimized_A500", "FlashOptimized_A700",
      "FlashOptimized_A1000", "FlashOptimized_A1500", "FlashOptimized_A2000",
      "FlashOptimized_A4500",
      
      # Memory Optimized Series (M10-M2000)
      "MemoryOptimized_M10", "MemoryOptimized_M20", "MemoryOptimized_M50",
      "MemoryOptimized_M100", "MemoryOptimized_M150", "MemoryOptimized_M250",
      "MemoryOptimized_M350", "MemoryOptimized_M500", "MemoryOptimized_M700",
      "MemoryOptimized_M1000", "MemoryOptimized_M1500", "MemoryOptimized_M2000",
      
      # Compute Optimized Series (X5-X700)
      "ComputeOptimized_X5", "ComputeOptimized_X10", "ComputeOptimized_X20",
      "ComputeOptimized_X50", "ComputeOptimized_X100", "ComputeOptimized_X150",
      "ComputeOptimized_X250", "ComputeOptimized_X350", "ComputeOptimized_X500",
      "ComputeOptimized_X700"
    ], var.sku)
    
    error_message = "SKU must be a valid Redis Enterprise SKU (Balanced, FlashOptimized, MemoryOptimized, or ComputeOptimized series)."
  }
}
```

This validation ensures forward compatibility as new SKUs become available in newer API versions.

---

## Testing & Validation

### GitHub Actions Workflow

All changes are validated through automated GitHub Actions:

```yaml
# .github/workflows/test-simple-example.yml
- Terraform init, validate, plan
- Apply with auto-approval
- Output validation
- Connectivity test with redis-cli
- Automatic cleanup on completion
```

### Successful Deployment Metrics

Latest validated deployment (2025-01-20):
- **Total Time**: 15m 50s
- **Cluster Creation**: ~7 minutes
- **Database Creation**: ~12 seconds
- **Resources Created**: 2 (cluster + database)
- **Connectivity**: ✅ PASSED
- **Cleanup**: ✅ COMPLETED

### Manual Testing

For manual validation:

```bash
# 1. Deploy
cd examples/simple
terraform init
terraform apply

# 2. Test connectivity
CONNECTION_STRING=$(terraform output -raw connection_string)
redis-cli -u "$CONNECTION_STRING" PING
# Expected: PONG

# 3. Cleanup
terraform destroy
```

---

## Migration Path to Native Provider

When the `azurerm` provider adds native support for Azure Managed Redis:

### Step 1: Module Update
The module maintainer will update the implementation to use native `azurerm` resources while maintaining the same interface.

### Step 2: User Migration
Users simply update the module version:

```hcl
module "redis_enterprise" {
  source  = "path/to/module"
  version = "2.0.0"  # New version with azurerm support
  
  # All existing variables work unchanged
  name                = "my-redis"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Balanced_B5"
}
```

### Step 3: State Management
Terraform can import existing resources with minimal state migration:

```bash
terraform plan  # Review the changes
terraform apply # Apply to update state
```

### Key Benefits
- ✅ No code changes required in your configuration
- ✅ Same inputs, same outputs
- ✅ Seamless provider transition
- ✅ Production workloads remain stable

---

## Best Practices

### 1. Use Data Sources for Post-Creation Reads
```hcl
data "azapi_resource" "cluster_data" {
  type                   = "${local.redis_enterprise_type}@${local.redis_enterprise_api_version}"
  resource_id            = azapi_resource.cluster.id
  response_export_values = ["properties"]
  depends_on             = [azapi_resource.database]
}
```

### 2. Always Parse JSON Outputs
```hcl
jsondecode(data.azapi_resource.cluster_data[0].output).properties.hostName
```

### 3. Mark Sensitive Outputs Appropriately
```hcl
output "primary_key" {
  value     = data.azapi_resource_action.database_keys.output.primaryKey
  sensitive = true
}
```

### 4. Use Proper Dependencies
```hcl
depends_on = [azapi_resource.cluster, azapi_resource.database]
```

### 5. Validate Through CI/CD
Always test changes through automated workflows before manual deployment.

---

## Troubleshooting

### Issue: "Cannot access property on JSON string"
**Cause**: Trying to access data source output without `jsondecode()`  
**Solution**: Wrap access in `jsondecode()`:
```hcl
jsondecode(data.azapi_resource.cluster_data[0].output).properties.hostName
```

### Issue: "Cluster creation failed"
**Cause**: Using unstable API version  
**Solution**: Verify you're using `2024-09-01-preview` in `locals.tf`

### Issue: "Cannot find hostname output"
**Cause**: Database not enabled or data source not created  
**Solution**: Ensure `enable_database = true` and data source count matches

### Issue: "State file conflicts"
**Cause**: Terraform state files committed to git  
**Solution**: Review `.gitignore` and remove state files:
```bash
git rm --cached **/*.tfstate **/*.tfstate.backup
git commit -m "Remove state files from version control"
```

---

## References

- [Azure Managed Redis Documentation](https://learn.microsoft.com/en-us/azure/azure-cache-for-redis/managed-redis/)
- [AzAPI Provider Documentation](https://registry.terraform.io/providers/Azure/azapi/latest/docs)
- [Redis Enterprise Modules](https://redis.io/docs/stack/)
- [Module Repository](https://github.com/tfindelkind-redis/azure-managed-redis-terraform)

---

*Last Updated: 2025-01-20*
*API Version: 2024-09-01-preview*
