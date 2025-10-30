# Quick Reference: Provider Switching

## 🚀 One-Line Commands

```bash
# Check current provider
./switch-provider.sh status

# Switch to AzureRM (recommended)
./switch-provider.sh to-azurerm

# Switch to AzAPI
./switch-provider.sh to-azapi
```

## 📋 What Each Provider Offers

### AzureRM (Recommended ✅)
- ✅ Native Terraform support
- ✅ Better IDE autocomplete
- ✅ Official HashiCorp provider
- ✅ Simpler configuration
- ✅ Built-in validation

### AzAPI
- ✅ Latest API features immediately
- ✅ Preview features access
- ✅ Direct ARM API control
- ⚠️  More complex configuration
- ⚠️  Limited IDE support

## 🔄 Migration Process

### The script automatically:
1. Backs up your state
2. Updates main.tf
3. Removes old provider resources
4. Imports to new provider
5. Validates with terraform plan

### No downtime, no data loss! ✅

## 📝 Manual Override

Set in `main.tf`:
```hcl
module "redis_enterprise" {
  source = "../../modules/managed-redis"
  
  use_azapi = false  # or true
  
  # ... rest of config
}
```

## 🆘 Troubleshooting

### Script can't find cluster ID
```bash
# Get it manually
az redis list --query "[].id" -o tsv
```

### Not authenticated
```bash
az login
az account set --subscription "your-sub-id"
```

### Plan shows unexpected changes
```bash
# Restore from backup
ls terraform.tfstate.backup-*
cp terraform.tfstate.backup-<timestamp> terraform.tfstate
```

## 📚 Full Documentation

See [PROVIDER-SWITCHING.md](./PROVIDER-SWITCHING.md) for complete guide.
