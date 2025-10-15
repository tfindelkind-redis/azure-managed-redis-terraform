# Troubleshooting Guide

This guide helps you diagnose and resolve common issues when deploying and managing Azure Managed Redis with this Terraform module.

## Common Deployment Issues

### 1. Authentication and Permission Issues

#### Problem: "insufficient privileges" or "authorization failed"
```
Error: building account: getting authenticated object ID: getting authenticated object from Azure CLI: parsing json result from the Azure CLI: waiting for the Azure CLI: exit status 1: ERROR: Please run 'az login' to setup account.
```

**Solutions:**
```bash
# Option 1: Azure CLI login
az login
az account set --subscription "your-subscription-id"

# Option 2: Service Principal (CI/CD)
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret" 
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"

# Option 3: Managed Identity (Azure VMs)
export ARM_USE_MSI=true
```

**Verify permissions:**
```bash
# Check current user/service principal permissions
az role assignment list --assignee $(az account show --query user.name -o tsv) --scope "/subscriptions/your-subscription-id"

# Required permissions:
# - Contributor (or Redis Enterprise Contributor) on resource group
# - Resource Group Contributor on subscription (to create RGs)
```

#### Problem: "Microsoft.Cache provider not registered"
```
Error: the Resource Provider "Microsoft.Cache" is not registered with Subscription "xxx"
```

**Solution:**
```bash
# Register the provider
az provider register --namespace Microsoft.Cache

# Check registration status
az provider show --namespace Microsoft.Cache --query "registrationState"
```

### 2. Resource Naming and Validation Issues

#### Problem: "name already exists" or "name not available"
```
Error: creating Redis Enterprise Cluster: name "my-redis" is not available
```

**Solutions:**
```bash
# Check name availability
az redis enterprise list --query "[].name" -o table

# Use unique naming with random suffix
variable "random_suffix" {
  default = random_id.redis.hex
}

resource "random_id" "redis" {
  byte_length = 4
}

module "redis_enterprise" {
  name = "${var.redis_name}-${var.random_suffix}"
  # ...
}
```

#### Problem: Invalid character in name
```
Error: "redis_Enterprise" is not a valid name. Name must contain only lowercase letters, numbers, and hyphens
```

**Solution:**
```hcl
variable "name" {
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.name))
    error_message = "Name must be 3-63 characters, start and end with alphanumeric, contain only lowercase letters, numbers, and hyphens."
  }
}
```

### 3. API Version and Provider Issues

#### Problem: "API version not supported" or "resource type not found"
```
Error: API version "2024-09-01-preview" is not available for resource type "Microsoft.Cache/redisEnterprise"
```

**Solutions:**
```bash
# Check available API versions
az provider show --namespace Microsoft.Cache --query "resourceTypes[?resourceType=='redisEnterprise'].apiVersions[0]"

# Update API version in locals.tf
locals {
  redis_enterprise_api_version = "2024-06-01-preview"  # Use supported version
}
```

#### Problem: AzAPI provider version conflicts
```
Error: Failed to query available provider packages
```

**Solution:**
```hcl
terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.15.0"  # Pin to specific version
    }
  }
}
```

### 4. SKU and Resource Availability Issues

#### Problem: "SKU not available in region"
```
Error: The SKU "Balanced_B5" is not available in location "West Europe"
```

**Solutions:**
```bash
# Check SKU availability by region
az redis enterprise show-skus --location "East US" --query "[].name" -o table

# Use region with better SKU availability
location = "East US"  # or "East US 2", "West US 2"
```

#### Problem: "Insufficient quota"
```
Error: Operation results in exceeding quota limits. Requested: 1, Limit: 0
```

**Solutions:**
```bash
# Check current quota usage
az vm list-usage --location "East US" --query "[?contains(name.value, 'redis')]"

# Request quota increase through Azure portal:
# Azure Portal > Subscriptions > Usage + quotas > Search "Redis" > Request increase
```

## Runtime and Connectivity Issues

### 1. Connection Issues

#### Problem: Connection timeout or refused
```bash
# Test basic connectivity
redis-cli -h your-hostname -p 10000 -a your-password ping
# (error) ERR Connection timed out
```

**Diagnostic steps:**
```bash
# 1. Check if Redis is running
az redis enterprise database show --cluster-name your-cluster --name default --resource-group your-rg

# 2. Verify hostname resolution
nslookup your-hostname

# 3. Test port connectivity 
telnet your-hostname 10000

# 4. Check firewall rules (if any)
az network nsg rule list --resource-group your-rg --nsg-name your-nsg
```

#### Problem: TLS/SSL certificate issues
```
(error) ERR SSL certificate verification failed
```

**Solutions:**
```bash
# Option 1: Connect with TLS validation
redis-cli -h your-hostname -p 10000 -a your-password --tls

# Option 2: Skip certificate verification (dev only)
redis-cli -h your-hostname -p 10000 -a your-password --tls --insecure

# Option 3: Update TLS version
redis-cli -h your-hostname -p 10000 -a your-password --tls --tls-ciphers "TLSv1.2"
```

### 2. Authentication Issues

#### Problem: "NOAUTH Authentication required"
```bash
redis-cli -h your-hostname -p 10000 ping
(error) NOAUTH Authentication required.
```

**Solutions:**
```bash
# Get access keys from Terraform output
terraform output -raw primary_key

# Connect with authentication
redis-cli -h your-hostname -p 10000 -a "$(terraform output -raw primary_key)" ping

# Or use connection string
redis-cli -u "$(terraform output -raw connection_string)" ping
```

#### Problem: "Invalid password"
```bash
redis-cli -h your-hostname -p 10000 -a wrong-password ping  
(error) ERR invalid password
```

**Solutions:**
```bash
# Regenerate access keys if needed
az redis enterprise database regenerate-key --cluster-name your-cluster --name default --resource-group your-rg --key-type Primary

# Get updated keys
terraform refresh
terraform output -raw primary_key
```

### 3. Module and Feature Issues

#### Problem: "unknown command" for Redis modules
```bash
redis-cli -u connection-string JSON.SET test $ '{"hello":"world"}'
(error) ERR unknown command 'JSON.SET'
```

**Solutions:**
```hcl
# Ensure modules are enabled in Terraform
module "redis_enterprise" {
  modules = [
    "RedisJSON",    # Enable JSON commands
    "RediSearch",   # Enable FT commands
    "RedisBloom",   # Enable BF commands
    "RedisTimeSeries" # Enable TS commands
  ]
}

# Verify modules are loaded
redis-cli -u connection-string MODULE LIST
```

#### Problem: Module not loading properly
```bash
redis-cli -u connection-string MODULE LIST
(empty list or reply)
```

**Solutions:**
```bash
# Check cluster and database status
az redis enterprise show --name your-cluster --resource-group your-rg --query "provisioningState"
az redis enterprise database show --cluster-name your-cluster --name default --resource-group your-rg --query "provisioningState"

# Wait for provisioning to complete, then test again
# Provisioning can take 15-30 minutes for modules
```

## Performance Issues

### 1. High Latency

#### Problem: Slow response times
```bash
redis-benchmark -h your-hostname -p 10000 -a your-password -c 1 -n 1000 -t ping_inline
# Average latency > 10ms
```

**Diagnostic steps:**
```bash
# 1. Check network proximity
ping your-hostname

# 2. Monitor Redis performance
redis-cli -h your-hostname -p 10000 -a your-password info stats

# 3. Check for memory pressure
redis-cli -h your-hostname -p 10000 -a your-password info memory

# 4. Monitor connection count
redis-cli -h your-hostname -p 10000 -a your-password info clients
```

**Solutions:**
- Deploy Redis in same region as applications
- Consider upgrading SKU for better performance
- Check for network security group rules adding latency
- Optimize client connection pooling

### 2. Memory Issues

#### Problem: Out of memory errors
```bash
redis-cli -u connection-string set test-key large-value
(error) OOM command not allowed when used memory > 'maxmemory'
```

**Solutions:**
```hcl
# Option 1: Upgrade SKU
module "redis_enterprise" {
  sku = "Balanced_B3"  # Upgrade from B1 to B3 for more memory
}

# Option 2: Configure eviction policy
module "redis_enterprise" {
  eviction_policy = "AllKeysLRU"  # Enable LRU eviction
}
```

```bash
# Monitor memory usage
redis-cli -u connection-string info memory | grep used_memory_human
redis-cli -u connection-string info memory | grep maxmemory_human
```

### 3. Connection Pool Issues

#### Problem: "too many connections"
```bash
redis-cli -u connection-string ping
(error) ERR max number of clients reached
```

**Solutions:**
```bash
# Check current connections
redis-cli -u connection-string info clients

# Monitor connection patterns
redis-cli -u connection-string CLIENT LIST

# Optimize application connection pooling
# Use connection pools with appropriate sizing
```

## Terraform-Specific Issues

### 1. State File Issues

#### Problem: "Resource already exists"
```
Error: A resource with the ID "/subscriptions/.../redisEnterprise/my-cluster" already exists
```

**Solutions:**
```bash
# Option 1: Import existing resource
terraform import 'azapi_resource.cluster[0]' '/subscriptions/your-sub/resourceGroups/your-rg/providers/Microsoft.Cache/redisEnterprise/your-cluster'

# Option 2: Remove from state and recreate
terraform state rm 'azapi_resource.cluster[0]'
terraform apply

# Option 3: Use different name
```

#### Problem: State file corruption
```
Error: Failed to load state: state snapshot was created by Terraform version, but this is version
```

**Solutions:**
```bash
# Upgrade Terraform state file format
terraform init -upgrade

# Or use specific Terraform version
terraform version  # Check current version
# Install matching version or upgrade workspace
```

### 2. Provider Configuration Issues

#### Problem: Multiple provider configurations
```
Error: Multiple provider configurations
```

**Solution:**
```hcl
# Use provider aliases if needed
provider "azurerm" {
  features {}
}

provider "azurerm" {
  alias           = "secondary"
  subscription_id = var.secondary_subscription_id
  features {}
}

module "redis_primary" {
  providers = {
    azurerm = azurerm
  }
}
```

### 3. Module Version Issues

#### Problem: "Module not found"
```
Error: Module not installed
```

**Solutions:**
```bash
# Initialize modules
terraform init

# Update modules
terraform init -upgrade

# Use specific module version
module "redis_enterprise" {
  source = "git::https://github.com/tfindelkind-redis/azure-managed-redis-terraform.git//modules/managed-redis?ref=v1.0.0"
}
```

## Monitoring and Debugging

### 1. Enable Terraform Debug Logging
```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log
terraform apply
```

### 2. Azure Resource Logs
```bash
# Enable diagnostic logging
az monitor diagnostic-settings create \
  --resource /subscriptions/your-sub/resourceGroups/your-rg/providers/Microsoft.Cache/redisEnterprise/your-cluster \
  --name redis-diagnostics \
  --logs '[{"category":"ConnectedClientList","enabled":true}]' \
  --metrics '[{"category":"AllMetrics","enabled":true}]' \
  --workspace your-log-analytics-workspace-id
```

### 3. Network Diagnostics
```bash
# Test network connectivity
nc -zv your-hostname 10000

# Trace network path  
traceroute your-hostname

# Check DNS resolution
dig your-hostname
```

### 4. Redis-specific Debugging
```bash
# Monitor Redis operations in real-time
redis-cli -u connection-string monitor

# Check Redis configuration
redis-cli -u connection-string config get "*"

# Get detailed server information
redis-cli -u connection-string info all
```

## Getting Help

### 1. Azure Support
- Create support ticket in Azure Portal
- Include Terraform configuration and error messages
- Provide correlation IDs from Azure activity log

### 2. GitHub Support
- GitHub Issues: [Create Issue](https://github.com/tfindelkind-redis/azure-managed-redis-terraform/issues)
- GitHub Discussions: [Ask Question](https://github.com/tfindelkind-redis/azure-managed-redis-terraform/discussions)
- Stack Overflow: Tag with `azure-redis` and `terraform`

### 3. Professional Support
- Microsoft Professional Services
- Redis Professional Services
- Terraform Consulting Partners

## Preventive Measures

### 1. Pre-deployment Validation
```bash
# Always run plan first
terraform plan

# Validate configuration
terraform validate

# Check formatting
terraform fmt -check
```

### 2. Testing Strategy
```bash
# Use separate workspace for testing
terraform workspace new testing
terraform workspace select testing

# Deploy with minimal SKU first
sku = "Balanced_B0"  # Test with smallest SKU

# Validate connectivity before production deployment
```

### 3. Monitoring Setup
```hcl
# Include monitoring in your deployment
resource "azurerm_monitor_metric_alert" "redis_memory" {
  name                = "redis-memory-alert"
  resource_group_name = var.resource_group_name
  scopes              = [module.redis_enterprise.cluster_id]

  criteria {
    metric_namespace = "Microsoft.Cache/redisEnterprise"
    metric_name      = "UsedMemoryPercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.alerts.id
  }
}
```

This troubleshooting guide covers the most common issues. For specific problems not covered here, please create an issue in the GitHub repository with detailed information about your configuration and error messages.
