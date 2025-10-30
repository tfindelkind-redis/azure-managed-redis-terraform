# Azure Managed Redis Terraform Module - Unofficial

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/tfindelkind-redis/azure-managed-redis-terraform)
[![CI](https://github.com/tfindelkind-redis/azure-managed-redis-terraform/actions/workflows/ci.yml/badge.svg)](https://github.com/tfindelkind-redis/azure-managed-redis-terraform/actions/workflows/ci.yml)
[![Nightly Validation](https://github.com/tfindelkind-redis/azure-managed-redis-terraform/actions/workflows/nightly-validation.yml/badge.svg)](https://github.com/tfindelkind-redis/azure-managed-redis-terraform/actions/workflows/nightly-validation.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **Deploy Azure Managed Redis with Terraform — AzAPI Today, Native Tomorrow**

A Terraform module for deploying Azure Managed Redis (Redis Enterprise) with seamless migration path from AzAPI to native azurerm provider.

## ⭐ Features

### Core Features
- **Azure Managed Redis**: Fully managed Redis Enterprise cluster with high performance
- **Dual Provider Support**: Seamlessly switch between AzAPI and AzureRM providers
- **Stable API**: Uses Azure Redis Enterprise API version `2025-05-01-preview` (proven stable)
- **Extended SKU Options**: Support for 40+ SKUs including Balanced, Flash-Optimized, Memory/Compute variants
- **Redis Modules**: Support for RedisJSON, RediSearch, RedisBloom, RedisTimeSeries

### Deployment Options
- **Clusterless Deployment**: Single-shard deployment with `EnterpriseCluster` policy
- **Clustered Deployment**: Multi-shard deployment with `OSSCluster` policy
- **High Availability**: Active-passive replication with automatic failover
- **Zone Redundancy**: Deploy across availability zones (AzAPI only)
- **Geo-Replication**: Active geo-replication across regions (AzAPI only)

### Data Persistence
- **RDB Persistence**: Point-in-time snapshots for backup and recovery (AzAPI only)
- **AOF Persistence**: Append-only file for maximum durability (AzAPI only)
- **Combined RDB + AOF**: Best of both worlds for optimal protection (AzAPI only)

### Security Features
- **TLS Encryption**: Minimum TLS 1.2 with encrypted client protocol
- **Access Keys Control**: Option to disable access keys for Entra ID-only authentication
- **Managed Identity**: SystemAssigned and UserAssigned identity support (AzureRM only)
- **Customer Managed Keys**: Encryption with your own Key Vault keys (AzureRM only)
- **Private Endpoints**: VNet integration support

### Developer Experience
- **Centralized Switch Script**: One command to switch between providers across all examples
- **Automated Testing**: Comprehensive test suite validates all examples
- **CI/CD Ready**: GitHub Actions workflows for automated validation
- **Future-Proof**: Ready for native azurerm provider migration

## 🏗️ Architecture

Azure Managed Redis consists of:

1. **Redis Enterprise Cluster** - The main compute and storage layer
2. **Database(s)** - Individual Redis databases within the cluster  
3. **Modules** - Optional Redis Enterprise modules (JSON, Search, etc.)
4. **Security** - TLS encryption and access key management

## 📚 Examples

All examples include a centralized switch script for seamless provider switching.

| 📁 Example | 📝 Description | 🎯 Use Case | 🔧 Features |
|-----------|----------------|-------------|-------------|
| [Simple](examples/simple/) | Basic deployment | Development & testing | Module-based, provider switching |
| [High Availability](examples/high-availability/) | HA configuration | Production apps | Active-passive replication, zones |
| [With Modules](examples/with-modules/) | Redis modules showcase | Feature exploration | RedisJSON, RediSearch, etc. |
| [Geo-Replication](examples/geo-replication/) | Multi-region deployment | Global applications | Active geo-replication (AzAPI) |
| [Clusterless + Persistence](examples/clusterless-with-persistence/) | Single-shard with persistence | Durable workloads | RDB + AOF persistence (AzAPI) |
| [Enterprise Security](examples/enterprise-security/) | Advanced security | Secure production | CMK, Managed Identity, Entra ID |

### 🔄 Provider Switching

Every example includes a centralized switch script:

```bash
# Switch to AzureRM provider
./switch-provider.sh to-azurerm

# Switch to AzAPI provider  
./switch-provider.sh to-azapi

# Check current provider status
./switch-provider.sh status
```

The script automatically:
- ✅ Updates configuration files
- ✅ Migrates Terraform state (if resources are deployed)
- ✅ Creates backups before changes
- ✅ Validates the configuration

### 🧪 Test All Examples

Run comprehensive tests across all examples:

```bash
# From repository root
./test-all-examples.sh
```

This validates:
- Provider switching in both directions
- Configuration validity
- Module integration

## �📦 Quick Start

### ⚡ Instant Setup with GitHub Codespaces (Recommended)

**Get started in 30 seconds** - no local installation required!

1. **Fork the repository**:
   - Go to: `https://github.com/tfindelkind-redis/azure-managed-redis-terraform`
   - Click the **"Fork"** button in the top-right corner
   - This creates your own copy of the repository

2. **Open in Codespaces**:
   - Click the green **"Code"** button on **your fork**
   - Select **"Codespaces"** tab
   - Click **"Create codespace on main"**
   
   Or use the quick link (after forking):
   [![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/tfindelkind-redis/azure-managed-redis-terraform)

3. **What you get instantly**:
   - ✅ **Pre-installed tools**: Terraform, Azure CLI, redis-cli
   - ✅ **VS Code environment** with extensions
   - ✅ **All examples ready** to deploy
   - ✅ **No local setup** required
  
### 🚀 Deploy in Codespaces (5 minutes)

Once your Codespace opens:

1. **Authenticate with Azure**:
```bash
# Login to Azure (opens browser for authentication)
az login

# Set your subscription (if you have multiple)
az account set --subscription "your-subscription-name-or-id"
```

2. **Navigate to simple example**:
```bash
cd examples/simple
```

3. **Customize the deployment**:

Each example includes a `terraform.tfvars.example` file. You **must** customize these values for your Azure environment:

```bash
# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
code terraform.tfvars
```

**Required Configuration** (adapt to your environment):

```hcl
# terraform.tfvars - Customize these values!

# Your Azure Subscription Details
resource_group_name = "rg-redis-demo"           # Resource group name (will be created by default)
location           = "eastus"                    # Azure region (e.g., eastus, westeurope, northeurope)
redis_name         = "redis-demo-unique123"      # Must be globally unique across Azure!

# Optional: Add metadata tags
environment = "development"                      # e.g., development, staging, production
owner      = "your-team-name"                   # Team or project name

# Optional: Use existing resource group
# create_resource_group = false                 # Set to false to use existing RG
```

**📍 Important Notes:**

| Setting | What to Change | Why |
|---------|---------------|-----|
| `resource_group_name` | Use your own RG name | Resource group that will be created (or used if exists) |
| `location` | Choose your region | Affects latency and data residency |
| `redis_name` | **Must be globally unique** | Forms DNS name: `<redis_name>.<region>.redisenterprise.cache.azure.net` |
| `create_resource_group` | Optional: `true`/`false` | Default: `true` (creates RG). Set to `false` to use existing RG |

**💡 Region Selection Tips:**

```bash
# List available Azure regions
az account list-locations --output table

# Common regions:
# - eastus, eastus2, westus, westus2, westus3
# - northeurope, westeurope
# - uksouth, ukwest
# - australiaeast, southeastasia
# - japaneast, japanwest
```

**🔐 Subscription Verification:**

Before deploying, verify your Azure subscription:

```bash
# Check current subscription
az account show --output table

# List all subscriptions
az account list --output table

# Switch subscription if needed
az account set --subscription "your-subscription-id"
```

4. **Deploy with Terraform commands**:
```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy the infrastructure
terraform apply
```

**What you'll see in the Codespace terminal**:
```
@vscode ➜ /workspaces/azure-managed-redis-terraform/examples/simple $ terraform init
@vscode ➜ /workspaces/azure-managed-redis-terraform/examples/simple $ terraform plan
@vscode ➜ /workspaces/azure-managed-redis-terraform/examples/simple $ terraform apply

Terraform will perform the following actions:
  # azurerm_resource_group.main will be created
  # module.redis_enterprise.azapi_resource.cluster[0] will be created
  # module.redis_enterprise.azapi_resource.database[0] will be created

Plan: 3 to add, 0 to change, 0 to destroy.

azurerm_resource_group.main: Creating...
azurerm_resource_group.main: Creation complete after 2s
module.redis_enterprise.azapi_resource.cluster[0]: Creating...
module.redis_enterprise.azapi_resource.cluster[0]: Still creating... [5m0s elapsed]
module.redis_enterprise.azapi_resource.cluster[0]: Creation complete after 12m30s
module.redis_enterprise.azapi_resource.database[0]: Creating...
module.redis_enterprise.azapi_resource.database[0]: Creation complete after 3m15s

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

5. **Test your deployment**:
```bash
# Test connection (using our pre-built validation script)
../../scripts/test-connection.sh
```

**Expected validation output**:
```
@vscode ➜ /workspaces/azure-managed-redis-terraform/examples/simple $ ../../scripts/test-connection.sh
[INFO] Getting connection details from Terraform...
[INFO] Testing connection to redis-demo-1698765432.northeurope.redisenterprise.cache.azure.net:10000
[INFO] Testing Redis PING...
[SUCCESS] PING successful
[INFO] Testing SET/GET operations...
[SUCCESS] SET operation successful
[SUCCESS] GET operation successful
[SUCCESS] All tests passed! Redis is working correctly.
[INFO] Connection string: rediss://:****@redis-demo-1698765432.northeurope.redisenterprise.cache.azure.net:10000
```

6. **Connect from your application**:
```bash
# Get the connection details for your app
terraform output redis_connection_info
terraform output -raw redis_connection_string
```

### 💻 Local Setup (Alternative)

If you prefer to work locally instead of using Codespaces:

**Prerequisites:**
- [Terraform](https://www.terraform.io/downloads) >= 1.3
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [redis-cli](https://redis.io/docs/getting-started/installation/) (optional, for testing)

**Setup Steps:**

```bash
# 1. Fork and clone your fork
git clone https://github.com/YOUR-USERNAME/azure-managed-redis-terraform.git
cd azure-managed-redis-terraform

# 2. Authenticate with Azure
az login

# Verify your subscription
az account show --output table

# Set subscription if you have multiple
az account set --subscription "your-subscription-id"

# 3. Navigate to an example
cd examples/simple

# 4. Configure for your environment
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values:
# - resource_group_name: Your resource group name
# - location: Your Azure region (e.g., eastus, westeurope)
# - redis_name: Globally unique name for your Redis instance
nano terraform.tfvars  # or use your preferred editor

# 5. Deploy
terraform init
terraform plan
terraform apply
```

**⚙️ Configuration Checklist:**
- ✅ Azure subscription is active and selected
- ✅ `terraform.tfvars` has unique `redis_name`
- ✅ `location` matches your preferred Azure region
- ✅ `resource_group_name` is set (RG will be created by default)
- ✅ If using existing RG, set `create_resource_group = false`

## 🔧 Requirements

| 📦 Component | 📋 Version |
|-------------|-----------|
| [Terraform](https://www.terraform.io/) | `>= 1.3` |
| [AzAPI Provider](https://registry.terraform.io/providers/Azure/azapi/latest) | `~> 1.15` |
| [AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | `~> 4.50` |

## 📖 Module Documentation

### Feature Support Matrix

For a comprehensive overview of all supported features, see [FEATURE-SUPPORT.md](FEATURE-SUPPORT.md).

**Quick Reference:**

| Feature | AzAPI | AzureRM |
|---------|-------|---------|
| Clusterless Deployment | ✅ | ✅ |
| Clustered Deployment | ✅ | ✅ |
| High Availability | ✅ | ✅ |
| RDB Persistence | ✅ | ❌ |
| AOF Persistence | ✅ | ❌ |
| Zone Redundancy | ✅ | ❌ |
| Geo-Replication | ✅ | ❌ |
| Managed Identity | ❌ | ✅ |
| Customer Managed Keys | ❌ | ✅ |

### Common Use Cases

#### Clusterless Deployment with Persistence
```hcl
module "redis" {
  source = "./modules/managed-redis"
  
  name                = "my-redis"
  resource_group_name = "my-rg"
  location            = "eastus"
  sku                 = "Balanced_B3"
  
  # Clusterless configuration
  clustering_policy = "EnterpriseCluster"
  
  # Persistence (requires AzAPI)
  persistence_rdb_enabled = true
  persistence_aof_enabled = true
  
  use_azapi = true
}
```

#### Enterprise Security with CMK
```hcl
module "redis" {
  source = "./modules/managed-redis"
  
  name                = "my-redis"
  resource_group_name = "my-rg"
  location            = "eastus"
  sku                 = "Balanced_B3"
  
  # Managed Identity (requires AzureRM)
  identity_type = "UserAssigned"
  identity_ids  = [azurerm_user_assigned_identity.redis.id]
  
  # Customer Managed Key
  customer_managed_key_enabled      = true
  customer_managed_key_vault_key_id = azurerm_key_vault_key.redis.id
  customer_managed_key_identity_id  = azurerm_user_assigned_identity.keyvault.id
  
  # Disable access keys for Entra ID only
  access_keys_authentication_enabled = false
  
  use_azapi = false
}
```

#### Geo-Replication
```hcl
# Primary region
module "redis_primary" {
  source = "./modules/managed-redis"
  
  name                = "redis-east"
  resource_group_name = "my-rg"
  location            = "eastus"
  sku                 = "Balanced_B3"
  
  geo_replication_enabled        = true
  geo_replication_group_nickname = "my-geo-group"
  
  use_azapi = true  # Required for geo-replication
}

# Secondary region
module "redis_west" {
  source = "./modules/managed-redis"
  
  name                = "redis-west"
  resource_group_name = "my-rg"
  location            = "westus"
  sku                 = "Balanced_B3"
  
  geo_replication_enabled        = true
  geo_replication_group_nickname = "my-geo-group"
  
  use_azapi = true
}
```

## 🔐 Security Best Practices

- ✅ **TLS Encryption**: All connections encrypted by default (minimum TLS 1.2)
- ✅ **Secure Keys**: API-based key retrieval (no CLI scripts)
- ✅ **Sensitive Outputs**: Access keys marked as sensitive
- ✅ **Network Security**: Private endpoints recommended for production (configure separately using Azure Private Link)
- ✅ **Compliance**: SOC, ISO, GDPR ready
- ✅ **Access Control**: Support for Azure AD authentication and RBAC


> **Note**: While this module provisions the Redis Enterprise cluster with a public endpoint, private endpoints should be configured separately using Azure Private Link resources for enhanced network security. This is the recommended approach for production deployments.


## 🔄 Migration Path

This module supports **both AzAPI and AzureRM providers** with seamless switching:

### Current State: Dual Provider Support

```hcl
module "redis" {
  source = "./modules/managed-redis"
  
  # Choose your provider
  use_azapi = true   # Use AzAPI for advanced features (persistence, geo-replication, zones)
  # OR
  use_azapi = false  # Use AzureRM for enterprise security (managed identity, CMK)
  
  # ... rest of configuration stays the same!
}
```

### Switching Providers

Use the centralized switch script in any example:

```bash
# Switch from AzAPI to AzureRM
./switch-provider.sh to-azurerm

# Switch from AzureRM to AzAPI
./switch-provider.sh to-azapi

# Check current status
./switch-provider.sh status
```

**What the script does:**
1. ✅ Updates configuration files (main.tf or terraform.tfvars)
2. ✅ Migrates Terraform state if resources are deployed
3. ✅ Creates automatic backups before changes
4. ✅ Validates configuration after switching
5. ✅ Handles both config-only and deployed resource scenarios

### When to Use Each Provider

**Use AzAPI when you need:**
- ✅ RDB or AOF persistence
- ✅ Geo-replication across regions
- ✅ Zone redundancy
- ✅ Defer upgrade control
- ✅ Latest API features

**Use AzureRM when you need:**
- ✅ Managed Identity (SystemAssigned or UserAssigned)
- ✅ Customer Managed Key (CMK) encryption
- ✅ Integration with other AzureRM resources
- ✅ Native Terraform resource experience

**You can switch anytime** - the module handles the complexity!

### �🔐 Authentication Setup only for Github Workflows
Choose your preferred authentication method:

- **🎯 [Azure Workload Identity (OIDC)](./AUTHENTICATION.md#recommended-azure-workload-identity-oidc)** - Modern, secure, no secrets
- **⚠️ [Service Principal](./AUTHENTICATION.md#traditional-service-principal-with-secrets)** - Traditional approach

#### 🚀 Quick OIDC Setup (Automated)
**One-command setup** with automatic GitHub secrets configuration:

## 🔄 Automated Updates

This repository stays current automatically:

- **Nightly Validation**: Tests against latest Azure APIs
- **Renovate Bot**: Updates provider versions  
- **CI Matrix**: Validates across provider versions
- **Auto-Issues**: Creates issues for API version drift
- **Comprehensive Testing**: All examples tested automatically with provider switching

### Continuous Integration

The repository includes automated testing:

```bash
# Test all examples with provider switching
./test-all-examples.sh
```

This script:
1. ✅ Tests each example's switch script status command
2. ✅ Switches to opposite provider
3. ✅ Verifies configuration was updated correctly
4. ✅ Switches back to original provider
5. ✅ Validates Terraform configuration
6. ✅ Reports comprehensive test results

All 6 examples are tested automatically in CI/CD pipelines.

## 📖 Additional Resources

### Documentation
- [Feature Support Matrix](FEATURE-SUPPORT.md) - Comprehensive feature documentation
- [Azure Managed Redis Documentation](https://docs.microsoft.com/en-us/azure/azure-cache-for-redis/cache-redis-enterprise-overview)
- [Redis Enterprise Cloud](https://redis.com/redis-enterprise-cloud/)
- [Terraform AzAPI Provider](https://registry.terraform.io/providers/Azure/azapi/latest/docs)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

### Module Features
- **Persistence**: RDB snapshots and AOF logging for data durability
- **Clustering**: Support for both clusterless (EnterpriseCluster) and clustered (OSSCluster) deployments
- **Security**: TLS encryption, access key control, managed identities, and customer-managed keys
- **High Availability**: Active-passive replication, zone redundancy, and geo-replication
- **Flexibility**: Switch between AzAPI and AzureRM providers as needed

### Examples Documentation
Each example includes detailed README with:
- Architecture diagrams
- Feature explanations
- Deployment instructions
- Testing procedures
- Provider switching guidance

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

- 📋 [Create an Issue](https://github.com/tfindelkind-redis/azure-managed-redis-terraform/issues)
- 💬 [GitHub Discussions](https://github.com/tfindelkind-redis/azure-managed-redis-terraform/discussions)
- 📧 [Contact the Author](https://github.com/tfindelkind-redis)

## ⭐ Star History

If this project helped you, please consider giving it a star! ⭐ 
