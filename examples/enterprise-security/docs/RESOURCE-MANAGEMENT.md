# 🔧 Resource Management Guide

## Quick Reference for Modular Deployment & Fixes

### 🚀 Initial Deployment

```bash
# Option 1: Guided modular deployment (RECOMMENDED)
./deploy-modular.sh

# Option 2: Interactive fix/deploy tool
./fix-resource.sh

# Option 3: Traditional full deployment
terraform apply
```

---

## 📦 Deploy Individual Components

### Network Only
```bash
terraform apply \
  -target="azurerm_virtual_network.main" \
  -target="azurerm_subnet.redis_pe"
```

### Managed Identities Only
```bash
terraform apply \
  -target="azurerm_user_assigned_identity.redis" \
  -target="azurerm_user_assigned_identity.keyvault_access"
```

### Key Vault Only
```bash
terraform apply \
  -target="azurerm_key_vault.main" \
  -target="azurerm_key_vault_key.cmk" \
  -target="azurerm_role_assignment.keyvault_crypto_user"
```

### Redis Cache Only
```bash
terraform apply -target="azurerm_managed_redis.main"
```

### Private Link Only
```bash
terraform apply \
  -target="azurerm_private_dns_zone.redis" \
  -target="azurerm_private_endpoint.redis" \
  -target="azurerm_private_dns_zone_virtual_network_link.redis"
```

---

## 🔄 Fix Broken Resources

### Scenario 1: Redis deployment failed
```bash
# Check what went wrong
terraform state show azurerm_managed_redis.main

# Redeploy only Redis
terraform apply -target="azurerm_managed_redis.main"
```

### Scenario 2: Private Endpoint not working
```bash
# Destroy and recreate Private Endpoint
terraform destroy -target="azurerm_private_endpoint.redis"
terraform apply -target="azurerm_private_endpoint.redis"
```

### Scenario 3: Key Vault access issues
```bash
# Redeploy role assignments
terraform apply -target="azurerm_role_assignment.keyvault_crypto_user"
```

### Scenario 4: Force recreation (taint)
```bash
# Mark resource for recreation
terraform taint azurerm_managed_redis.main

# Redeploy (will destroy and recreate)
terraform apply -target="azurerm_managed_redis.main"
```

---

## 🧪 Testing Strategy

### After Each Component
```bash
# Network deployed? Test connectivity
az network vnet show --name <vnet-name> --resource-group <rg>

# Key Vault deployed? Test access
az keyvault show --name <kv-name>

# Redis deployed? Check status
az redisenterprise show --cluster-name <name> --resource-group <rg>

# Private Endpoint deployed? Test DNS
dig <redis-hostname>
```

### Full Integration Test
```bash
# Deploy test function
./create-test-function.sh

# Or use the automated test
./test-local.sh
```

---

## 🛡️ Common Issues & Solutions

### Issue: "Resource already exists"
**Solution**: Import existing resource
```bash
# Get Azure resource ID
RESOURCE_ID=$(az redisenterprise show --name <name> --resource-group <rg> --query id -o tsv)

# Import into Terraform state
terraform import azurerm_managed_redis.main "$RESOURCE_ID"

# Now you can manage it with Terraform
terraform apply
```

### Issue: "Key Vault not accessible"
**Solution**: Check and fix access policies
```bash
# Verify identity has access
az role assignment list --scope <keyvault-id>

# Redeploy role assignment
terraform apply -target="azurerm_role_assignment.keyvault_crypto_user"
```

### Issue: "Private Endpoint DNS not resolving"
**Solution**: Recreate DNS zone link
```bash
# Destroy DNS link
terraform destroy -target="azurerm_private_dns_zone_virtual_network_link.redis"

# Recreate DNS link
terraform apply -target="azurerm_private_dns_zone_virtual_network_link.redis"
```

### Issue: "Redis stuck in 'Creating' state"
**Solution**: Check deployment logs
```bash
# View activity logs
az monitor activity-log list \
  --resource-group <rg> \
  --query "[?contains(resourceId, 'redis')].{Time:eventTimestamp, Status:status.value, Message:properties.statusMessage}" \
  --output table

# If needed, destroy and redeploy
terraform destroy -target="azurerm_managed_redis.main"
terraform apply -target="azurerm_managed_redis.main"
```

---

## 📊 View Current State

```bash
# List all deployed resources
terraform state list

# Show specific resource details
terraform state show azurerm_managed_redis.main

# View outputs
terraform output

# See what would change
terraform plan
```

---

## 🗑️ Cleanup Options

### Remove Specific Component
```bash
# Remove Private Link only
terraform destroy \
  -target="azurerm_private_dns_zone_virtual_network_link.redis" \
  -target="azurerm_private_endpoint.redis" \
  -target="azurerm_private_dns_zone.redis"

# Remove Redis only (keeps infrastructure)
terraform destroy -target="azurerm_managed_redis.main"

# Remove everything
terraform destroy
```

### Safe Cleanup (preserve data)
```bash
# 1. Export connection details first
terraform output > connection-details-backup.txt

# 2. Remove from state (keeps Azure resource)
terraform state rm azurerm_managed_redis.main

# 3. Later, re-import if needed
terraform import azurerm_managed_redis.main "/subscriptions/.../redis-name"
```

---

## 💡 Pro Tips

### 1. **Always plan before apply**
```bash
terraform plan -target="azurerm_managed_redis.main" -out=plan.tfplan
terraform apply plan.tfplan
```

### 2. **Use workspaces for environments**
```bash
terraform workspace new dev
terraform workspace new prod
terraform workspace select dev
```

### 3. **Lock state during deployment**
```bash
# State is automatically locked during apply
# But you can manually lock if needed
terraform force-unlock <lock-id>
```

### 4. **Backup state before risky changes**
```bash
cp terraform.tfstate terraform.tfstate.backup
```

### 5. **Use -parallelism for faster deploys**
```bash
terraform apply -parallelism=10
```

### 6. **Refresh state without changes**
```bash
terraform refresh
```

---

## 🎯 Typical Workflow

### Initial Deployment
```bash
1. ./deploy-modular.sh              # Guided deployment
2. Wait for each phase to complete
3. Test after each phase
4. If failure, fix only broken component
```

### When Something Breaks
```bash
1. ./fix-resource.sh                # Interactive menu
2. Select "View component details"  # Investigate
3. Select "Deploy/Update"           # Fix broken component
4. Test again
```

### Production Updates
```bash
1. terraform plan                   # See what will change
2. terraform apply -target=<specific-resource>  # Update one thing
3. Test in staging first
4. Apply to production
```

---

## 📞 Need Help?

### Check Logs
```bash
# Terraform debug output
TF_LOG=DEBUG terraform apply

# Azure activity logs
az monitor activity-log list --resource-group <rg>
```

### Get Resource Info
```bash
# Using Terraform
terraform state show <resource>

# Using Azure CLI
az resource show --ids <resource-id>
```

### Validate Configuration
```bash
terraform validate
terraform fmt -check
```
