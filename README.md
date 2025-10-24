# Azure Managed Redis Terraform Module - Unofficial

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/tfindelkind-redis/azure-managed-redis-terraform)
[![CI](https://github.com/tfindelkind-redis/azure-managed-redis-terraform/actions/workflows/ci.yml/badge.svg)](https://github.com/tfindelkind-redis/azure-managed-redis-terraform/actions/workflows/ci.yml)
[![Nightly Validation](https://github.com/tfindelkind-redis/azure-managed-redis-terraform/actions/workflows/nightly-validation.yml/badge.svg)](https://github.com/tfindelkind-redis/azure-managed-redis-terraform/actions/workflows/nightly-validation.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 📚 Examples

| 📁 Example                                         | 📝 Description             | 🎯 Use Case                |
|----------------------------------------------------|----------------------------|----------------------------|
| [Simple](examples/simple/)                         | Basic deployment           | Development & testing      |
| [With Modules](examples/with-modules/)             | Redis modules showcase     | Feature exploration        |
| [High Availability](examples/high-availability/)   | HA configuration           | High-availability apps     |
| [Geo-Replication](examples/geo-replication/)       | Global deployment          | Worldwide applications     |

> **Deploy Azure Managed Redis with Terraform — AzAPI Today, Native Tomorrow**

A Terraform module for deploying Azure Managed Redis (Redis Enterprise) with seamless migration path from AzAPI to native azurerm provider.

## ⭐ Features

- **Azure Managed Redis**: Fully managed Redis Enterprise cluster with high performance
- **Stable API**: Uses Azure Redis Enterprise API version `2024-09-01-preview` (proven stable)
- **Extended SKU Options**: Support for 40+ SKUs including Balanced, Flash-Optimized, Memory/Compute variants
- **Future-Proof**: Built with AzAPI provider, ready for azurerm migration
- **Redis Modules**: Support for RedisJSON, RediSearch, RedisBloom, RedisTimeSeries
- **Configurable**: High availability, security, and monitoring options
- **CI/CD Ready**: GitHub Actions workflows for automated validation and deployment
- **Geo-Replication**: Support for active geo-replication across regions

## 🏗️ Architecture

Azure Managed Redis consists of:

1. **Redis Enterprise Cluster** - The main compute and storage layer
2. **Database(s)** - Individual Redis databases within the cluster  
3. **Modules** - Optional Redis Enterprise modules (JSON, Search, etc.)
4. **Security** - TLS encryption and access key management

## 🛡️ Safety Features

> **🔒 Resource Group Protection**: All resource groups are protected from accidental deletion using Terraform's `prevent_destroy` lifecycle rule.

**Key Safety Measures**:
- ✅ Resource groups cannot be deleted via `terraform destroy`
- ✅ Prevents accidental infrastructure removal
- ✅ Protects critical Azure resources (RBAC, logs, monitoring)
- ✅ Safe for CI/CD - uses existing resource groups

## 📦 Quick Start

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/tfindelkind-redis/azure-managed-redis-terraform)
[![CI](https://github.com/tfindelkind-redis/azure-managed-redis-terraform/actions/workflows/ci.yml/badge.svg)](https://github.com/tfindelkind-redis/azure-managed-redis-terraform/actions/workflows/ci.yml)
[![Nightly Validation](https://github.com/tfindelkind-redis/azure-managed-redis-terraform/actions/workflows/nightly-validation.yml/badge.svg)](https://github.com/tfindelkind-redis/azure-managed-redis-terraform/actions/workflows/nightly-validation.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 📚 Examples

| 📁 Example                                         | 📝 Description             | 🎯 Use Case                |
|----------------------------------------------------|----------------------------|----------------------------|
| [Simple](examples/simple/)                         | Basic deployment           | Development & testing      |
| [With Modules](examples/with-modules/)             | Redis modules showcase     | Feature exploration        |
| [High Availability](examples/high-availability/)   | HA configuration           | High-availability apps     |
| [Geo-Replication](examples/geo-replication/)       | Global deployment          | Worldwide applications     |

> **Deploy Azure Managed Redis with Terraform — AzAPI Today, Native Tomorrow**

A Terraform module for deploying Azure Managed Redis (Redis Enterprise) with seamless migration path from AzAPI to native azurerm provider.

## ⭐ Features

- **Azure Managed Redis**: Fully managed Redis Enterprise cluster with high performance
- **Stable API**: Uses Azure Redis Enterprise API version `2024-09-01-preview` (proven stable)
- **Extended SKU Options**: Support for 40+ SKUs including Balanced, Flash-Optimized, Memory/Compute variants
- **Future-Proof**: Built with AzAPI provider, ready for azurerm migration
- **Redis Modules**: Support for RedisJSON, RediSearch, RedisBloom, RedisTimeSeries
- **Configurable**: High availability, security, and monitoring options
- **CI/CD Ready**: GitHub Actions workflows for automated validation and deployment
- **Geo-Replication**: Support for active geo-replication across regions

## 🏗️ Architecture

Azure Managed Redis consists of:

1. **Redis Enterprise Cluster** - The main compute and storage layer
2. **Database(s)** - Individual Redis databases within the cluster  
3. **Modules** - Optional Redis Enterprise modules (JSON, Search, etc.)
4. **Security** - TLS encryption and access key management

**Key Safety Measures**:
- ✅ Resource groups cannot be deleted via `terraform destroy`
- ✅ Prevents accidental infrastructure removal
- ✅ Protects critical Azure resources (RBAC, logs, monitoring)
- ✅ Safe for CI/CD - uses existing resource groups

## �📦 Quick Start

### ⚡ Instant Setup with GitHub Codespaces (Recommended)

**Get started in 30 seconds** - no local installation required!

1. **Open in Codespaces**:
   [![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/tfindelkind-redis/azure-managed-redis-terraform)

2. **Or manually create a Codespace**:
   - Go to: `https://github.com/tfindelkind-redis/azure-managed-redis-terraform`
   - Click the green **"Code"** button → **"Codespaces"** → **"Create codespace on main"**

3. **What you get instantly**:
   - ✅ **Pre-installed tools**: Terraform, Azure CLI, redis-cli
   - ✅ **VS Code environment** with extensions
   - ✅ **All examples ready** to deploy
   - ✅ **No local setup** required

### 🔐 Authentication Setup
Choose your preferred authentication method:

- **🎯 [Azure Workload Identity (OIDC)](./AUTHENTICATION.md#recommended-azure-workload-identity-oidc)** - Modern, secure, no secrets
- **⚠️ [Service Principal](./AUTHENTICATION.md#traditional-service-principal-with-secrets)** - Traditional approach

#### 🚀 Quick OIDC Setup (Automated)
**One-command setup** with automatic GitHub secrets configuration:

```bash
# Clone the repository and run the setup script
git clone https://github.com/tfindelkind-redis/azure-managed-redis-terraform.git
cd azure-managed-redis-terraform
./scripts/setup-oidc.sh
```

**Prerequisites**: Azure CLI and GitHub CLI authenticated

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

3. **Customize the deployment** (edit `terraform.tfvars.example`):
```bash
# Copy and edit the example variables
cp terraform.tfvars.example terraform.tfvars

# Edit with your preferred values
code terraform.tfvars
```

Example `terraform.tfvars`:
```hcl
resource_group_name = "rg-azure-managed-redis-terraform"
location           = "northeurope"
redis_name         = "redis-demo-$(date +%s)"
environment        = "demo"
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
[INFO] Testing RedisJSON module...
[SUCCESS] RedisJSON working
[SUCCESS] All tests passed! Redis is working correctly.
[INFO] Connection string: rediss://:****@redis-demo-1698765432.northeurope.redisenterprise.cache.azure.net:10000
```

6. **Connect from your application**:
```bash
# Get the connection details for your app
terraform output redis_connection_info
terraform output -raw redis_connection_string
```

### 💻 Local Development Alternative

If you prefer local development:

2. **Create `main.tf`**:
```hcl
# Configure providers
terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.80" }
    azapi   = { source = "Azure/azapi", version = "~> 1.15" }
  }
}

provider "azurerm" { features {} }
provider "azapi" {}

# Create resource group
resource "azurerm_resource_group" "demo" {
  name     = "rg-azure-managed-redis-terraform"
  location = "northeurope"

  lifecycle {
    prevent_destroy = true
  }
}

# Deploy Redis Enterprise
module "redis_enterprise" {
  source = "git::https://github.com/tfindelkind-redis/azure-managed-redis-terraform.git//modules/managed-redis"
  
  name                = "my-redis-cluster"
  resource_group_name = azurerm_resource_group.demo.name
  location            = azurerm_resource_group.demo.location
  
  # Basic configuration
  sku     = "Balanced_B1"
  modules = ["RedisJSON", "RediSearch"]
  
  # Security settings
  high_availability   = true
  minimum_tls_version = "1.2"
}

# Output connection details
output "redis_connection_info" {
  value = {
    hostname = module.redis_enterprise.hostname
    port     = module.redis_enterprise.port
  }
}

output "redis_connection_string" {
  value     = module.redis_enterprise.connection_string
  sensitive = true
}
```

3. **Deploy the infrastructure**:
```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy (takes ~15-20 minutes)
terraform apply
```

4. **What you'll see during deployment**:
```
Plan: 3 to add, 0 to change, 0 to destroy.

azurerm_resource_group.demo: Creating...
azurerm_resource_group.demo: Creation complete after 2s
module.redis_enterprise.azapi_resource.cluster[0]: Creating...
module.redis_enterprise.azapi_resource.cluster[0]: Still creating... [5m0s elapsed]
module.redis_enterprise.azapi_resource.cluster[0]: Creation complete after 12m30s
module.redis_enterprise.azapi_resource.database[0]: Creating...
module.redis_enterprise.azapi_resource.database[0]: Creation complete after 3m15s

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:
redis_connection_info = {
  "hostname" = "my-redis-cluster.northeurope.redisenterprise.cache.azure.net"
  "port" = 10000
}
redis_connection_string = <sensitive>
```

5. **Test your Redis deployment**:
```bash
# Get connection details
HOSTNAME=$(terraform output -raw hostname)
PORT=$(terraform output -raw port)
PRIMARY_KEY=$(terraform output -raw primary_key)

# Test basic connectivity (requires redis-cli)
redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning ping
# Expected output: PONG

# Test RedisJSON module
redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning JSON.SET user:1 $ '{"name":"John","age":30}'
# Expected output: OK

redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning JSON.GET user:1 $.name  
# Expected output: ["John"]

# Test RediSearch module
redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning FT.CREATE users_idx ON JSON PREFIX 1 user: SCHEMA $.name AS name TEXT
# Expected output: OK
```

6. **What you get**:
- ✅ **Fully managed Redis Enterprise cluster** in Azure
- ✅ **High availability** across availability zones
- ✅ **TLS encryption** for all connections
- ✅ **RedisJSON & RediSearch modules** enabled
- ✅ **Comprehensive examples** from development to geo-replication deployments
- ✅ **Configurable security** with customizable security settings
- ✅ **Automated CI/CD** with GitHub Actions workflows
- ✅ **Connection details** ready for your applications

## �📚 Examples

| Example | Description | Use Case |
|--------------------------------------------------|------------------------|------------------------|
| [Simple](examples/simple/)                         | Single standalone cluster  | Development/testing        |
| [With-Modules](examples/with-modules/)             | Cluster with Redis modules | Feature-rich applications  |
| [High-Availability](examples/high-availability/)   | HA enabled cluster         | Production workloads       |
| [Geo-Replication](examples/geo-replication/)       | Active geo-replication     | Worldwide applications     |

## 🔧 Requirements

| 📦 Component                                                                                                | 📋 Version    |
|-------------------------------------------------------------------------------------------------------------|---------------|
| [Terraform](https://www.terraform.io/)                                                                      | `>= 1.3`      |
| [AzAPI Provider](https://registry.terraform.io/providers/Azure/azapi/latest)                                | `~> 1.15`     |
| [AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)                        | `~> 3.80`     |

## 📋 Module Documentation

For detailed input/output documentation, see: [Module Documentation](modules/managed-redis/README.md)

### Key Inputs

- `name` - Redis Enterprise cluster name
- `resource_group_name` - Azure resource group
- `location` - Azure region
- `sku` - Performance tier (Balanced_B0 to Flash_F1500)
- `modules` - Redis Enterprise modules to enable
- `high_availability` - Enable HA across availability zones

### Key Outputs

- `hostname` - Redis database hostname
- `port` - Redis database port (10000)
- `primary_key` / `secondary_key` - Access keys (sensitive)
- `connection_string` - Full Redis connection string for reference (sensitive)

> **Note**: For connecting to Azure Managed Redis, use explicit parameters (`-h`, `-p`, `--tls`, `-a`) instead of the connection string URL format. See examples above.

## 🔐 Security Best Practices

- ✅ **TLS Encryption**: All connections encrypted by default (minimum TLS 1.2)
- ✅ **Secure Keys**: API-based key retrieval (no CLI scripts)
- ✅ **Sensitive Outputs**: Access keys marked as sensitive
- ✅ **Network Security**: Private endpoints recommended for production (configure separately using Azure Private Link)
- ✅ **Compliance**: SOC, ISO, GDPR ready
- ✅ **Access Control**: Support for Azure AD authentication and RBAC

> **Note**: While this module provisions the Redis Enterprise cluster, private endpoints should be configured separately using Azure Private Link resources for enhanced network security. This is the recommended approach for production deployments.

## 🌍 Geo-Replication Support

Deploy with active geo-replication across Azure regions for global applications:

```hcl
# Primary region
module "redis_primary" {
  source = "./modules/managed-redis"
  name   = "redis-primary"
  location = "northeurope"
  # ... other configuration
}

# Secondary region with geo-replication
module "redis_secondary" {
  source = "./modules/managed-redis"
  name   = "redis-secondary"
  location = "westeurope"
  # ... other configuration
}
```

## 🚀 CI/CD Integration

### GitHub Actions with OIDC (Recommended)

```yaml
name: Deploy Redis Infrastructure

on:
  push:
    branches: [main]

permissions:
  id-token: write   # Required for OIDC
  contents: read

env:
  TF_VERSION: "1.7.5"
  ARM_SKIP_PROVIDER_REGISTRATION: "true"

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: ${{ env.TF_VERSION }}
    
    - name: Azure CLI Login
      uses: azure/login@v2
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
        enable-AzPSSession: false

    - name: Set ARM Environment Variables
      run: |
        echo "ARM_CLIENT_ID=${{ secrets.AZURE_CLIENT_ID }}" >> $GITHUB_ENV
        echo "ARM_TENANT_ID=${{ secrets.AZURE_TENANT_ID }}" >> $GITHUB_ENV
        echo "ARM_SUBSCRIPTION_ID=${{ secrets.AZURE_SUBSCRIPTION_ID }}" >> $GITHUB_ENV
        echo "ARM_USE_OIDC=true" >> $GITHUB_ENV
    
    - name: Deploy Redis Enterprise
      run: |
        cd examples/simple
        
        # Create terraform.tfvars
        cat > terraform.tfvars << EOF
        resource_group_name = "rg-azure-managed-redis-terraform"
        location = "northeurope"
        redis_name = "redis-demo-$(date +%Y%m%d%H%M%S)"
        environment = "production"
        create_resource_group = false
        EOF
        
        terraform init
        terraform plan
        terraform apply -auto-approve
```

### GitHub Actions with Service Principal (Legacy)

```yaml
- name: Deploy Redis Enterprise
  run: |
    terraform init
    terraform plan
    terraform apply -auto-approve
  env:
    ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
    ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
    ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
    ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
```

> **Note**: OIDC authentication is recommended for better security (no stored secrets). The ARM environment variables step is **required** for the AzAPI provider to work with OIDC authentication, as the AzAPI provider needs explicit environment variables to authenticate properly.

## 🔄 Migration Path

This module is designed for seamless migration from AzAPI to native azurerm:

### Today (AzAPI)
```hcl
module "redis" {
  source = "./modules/managed-redis"
  use_azapi = true  # Current default
  # ... configuration
}
```

### Tomorrow (Native)
```hcl  
module "redis" {
  source = "./modules/managed-redis"
  use_azapi = false  # Switch when azurerm supports it
  # ... same configuration - no changes needed!
}
```

## 🔄 Automated Updates

This repository stays current automatically:

- **Nightly Validation**: Tests against latest Azure APIs
- **Renovate Bot**: Updates provider versions  
- **CI Matrix**: Validates across provider versions
- **Auto-Issues**: Creates issues for API version drift

## 🤝 Contributing

We welcome contributions! Please see:

- [Contributing Guidelines](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Security Policy](SECURITY.md)

### Development Setup

```bash
# Clone the repository
git clone https://github.com/tfindelkind-redis/azure-managed-redis-terraform.git
cd azure-managed-redis-terraform

# Install pre-commit hooks
pre-commit install

# Run validation and tests
terraform fmt -recursive
terraform validate
tflint --recursive
tfsec .
```

## 📖 Additional Resources

- [Azure Managed Redis Documentation](https://docs.microsoft.com/en-us/azure/azure-cache-for-redis/cache-redis-enterprise-overview)
- [Redis Enterprise Cloud](https://redis.com/redis-enterprise-cloud/)
- [Terraform AzAPI Provider](https://registry.terraform.io/providers/Azure/azapi/latest/docs)
- [Migration Guide](docs/MIGRATION.md)
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

- 📋 [Create an Issue](https://github.com/tfindelkind-redis/azure-managed-redis-terraform/issues)
- 💬 [GitHub Discussions](https://github.com/tfindelkind-redis/azure-managed-redis-terraform/discussions)
- 📧 [Contact the Author](https://github.com/tfindelkind-redis)

## ⭐ Star History

If this project helped you, please consider giving it a star! ⭐ 
