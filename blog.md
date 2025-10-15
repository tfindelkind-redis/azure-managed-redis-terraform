# Deploy Azure Managed Redis with Terraform — AzAPI Today, Native Tomorrow

*By Thomas Findelkind, Redis Developer Advocate*

> **TL;DR:** Azure Managed Redis is here — a fully managed, Redis Enterprise–powered service. Terraform support is still catching up, but with an AzAPI module, you can deploy today and stay ready for tomorrow's provider updates.

---

## Why Azure Managed Redis?

Azure Managed Redis brings the **power of Redis Enterprise** directly into Azure's control plane. It combines:
- Redis Enterprise's performance, modules, and HA capabilities  
- Azure's managed experience, integrated billing, and security model  

Managed Redis supports modules such as **RedisJSON**, **RediSearch**, and **RedisBloom**, and will expand further as the service matures.

For many teams working with infrastructure as code, that means:  
> "I need to deploy Redis Enterprise on Azure with Terraform now — but the azurerm provider doesn't support it yet."

This is where AzAPI comes in as the bridge solution.

---

## The AzAPI Approach

Since the azurerm provider doesn't yet support Azure Managed Redis, we can use the AzAPI provider to interact directly with Azure's REST APIs. This approach offers several advantages:

| Principle | Description |
|------------|--------------|
| **1. Immediate access** | Deploy Azure Managed Redis resources as soon as they're available in Azure |
| **2. Future-proof design** | Module interface stays stable for easy migration to azurerm later |
| **3. Direct API access** | Use Azure REST APIs through Terraform without waiting for provider updates |
| **4. Working examples** | Ready-to-use examples you can deploy immediately |

## Quick Start with GitHub Codespaces

The fastest way to get started is using the pre-configured development environment:

➡️ **[Open in GitHub Codespaces](https://codespaces.new/tfindelkind-redis/azure-managed-redis-terraform)** ⚡

This gives you:
- Pre-installed Terraform, Azure CLI, and Redis tools
- Ready-to-use examples in the `/examples` directory  
- One-command deployment: `terraform init && terraform apply`

You can also find the full repository here:  
➡️ [**tfindelkind-redis/azure-managed-redis-terraform**](https://github.com/tfindelkind-redis/azure-managed-redis-terraform)

---

## Architecture Overview

A typical Azure Managed Redis setup consists of:

1. A **Redis Enterprise Cluster** resource  
2. One or more **Databases** under that cluster  
3. Optional **Modules** (RedisJSON, RediSearch, RedisBloom)  
4. **Access keys** managed securely through Azure APIs  

Terraform provisions both cluster and database layers using the AzAPI provider — for now — until `azurerm` gains full native support.

---

## Terraform Module Interface

### Inputs
```hcl
variable "name"                { type = string }
variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "sku"                 { type = string   default = "Balanced_B0" }
variable "modules"             { type = list(string) default = ["RedisJSON","RediSearch"] }
variable "minimum_tls_version" { type = string   default = "1.2" }
variable "high_availability"   { type = bool     default = true }
variable "use_azapi"           { type = bool     default = true }
```

### Outputs
```hcl
output "cluster_id"  { value = azapi_resource.cluster.id }
output "db_id"       { value = azapi_resource.db.id }
output "hostname"    { value = azapi_resource.db.name }
output "primary_key" { value = data.azapi_resource_action.db_keys.output.primaryKey  sensitive = true }
output "secondary_key" { value = data.azapi_resource_action.db_keys.output.secondaryKey  sensitive = true }
```

This contract remains identical when you later switch to native Terraform resources.

---

## Implementation: **AzAPI (Today)**

Since the `azurerm` provider doesn't yet expose Managed Redis resources, we use `azapi_resource`.

### Cluster
```hcl
resource "azapi_resource" "cluster" {
  type      = "Microsoft.Cache/redisEnterprise@2025-04-01"
  name      = var.name
  location  = var.location
  parent_id = azurerm_resource_group.rg.id
  body = {
    sku = { name = var.sku }
    properties = {
      highAvailability  = var.high_availability ? "Enabled" : "Disabled"
      minimumTlsVersion = var.minimum_tls_version
    }
  }
  schema_validation_enabled = true
}
```

### Database
```hcl
resource "azapi_resource" "db" {
  type      = "Microsoft.Cache/redisEnterprise/databases@2025-04-01"
  name      = "default"
  parent_id = azapi_resource.cluster.id
  body = {
    properties = {
      clientProtocol   = "Encrypted"
      evictionPolicy   = "NoEviction"
      clusteringPolicy = "EnterpriseCluster"
      modules          = [for m in var.modules : { name = m }]
    }
  }
  depends_on = [azapi_resource.cluster]
}
```

### Access Keys (no scripts needed)
```hcl
data "azapi_resource_action" "db_keys" {
  type        = "Microsoft.Cache/redisEnterprise/databases@2025-07-01"
  resource_id = azapi_resource.db.id
  action      = "listKeys"
  method      = "POST"
  response_export_values = ["primaryKey", "secondaryKey"]
}
```

This calls Azure's documented **List Keys** API action — no `null_resource`, no local scripts, just clean data source logic.

---

## Implementation: **Native (Tomorrow)**

When Terraform's AzureRM provider adds Managed Redis support, this module will:
- Detect provider availability, or  
- Allow manual switch via `use_azapi = false`

Your consumer code won't change — only the module internals will.

That means: *No breaking change, no refactor.*

---

## Available Examples

The repository includes four complete examples to get you started:

```
azure-managed-redis-terraform/
  examples/
    simple/                    # Basic Redis cluster for development
    with-modules/             # Showcase Redis modules (JSON, Search, etc.)  
    high-availability/        # HA configuration for critical workloads
    multi-region/            # Global deployment pattern
  modules/
    managed-redis/           # Reusable Terraform module
  .devcontainer/             # GitHub Codespaces configuration
  scripts/                   # Validation and testing utilities
```

### Quick Examples

**Simple deployment:**
```bash
cd examples/simple
terraform init && terraform apply
```

**With Redis modules:**
```bash  
cd examples/with-modules
terraform init && terraform apply
```

**High availability setup:**
```bash
cd examples/high-availability  
terraform init && terraform apply
```

### Automated Quality Assurance

The repository includes CI/CD workflows that automatically:

- **Validate Terraform code**: Run `terraform fmt`, `tflint`, and `tfsec` on every change
- **Test multiple provider versions**: Matrix testing across AzAPI provider versions  
- **Monitor API changes**: Nightly validation against Azure APIs to catch breaking changes
- **Update dependencies**: Renovate automatically updates provider versions and Azure API versions

This ensures the examples stay current as Azure Managed Redis evolves.

---

## Testing Your Deployment

The repository includes validation scripts to test your Redis deployment:

```bash
# Test connection and basic operations
./scripts/test-connection.sh

# Validate deployment configuration  
./scripts/validate-deployment.sh
```

Or test manually:
```bash
# Basic connectivity
redis-cli -h <hostname> -p 10000 -a <primary_key> ping

# Test RedisJSON module (if enabled)
redis-cli -h <hostname> -p 10000 -a <primary_key> JSON.SET mykey $ '{"hello":"world"}'
```

Use [**RedisInsight**](https://redis.io/insight/) for visual inspection and management.

---

## Migration & Future Path

**From existing Redis services:**
If you're currently using Azure Cache for Redis or Redis Enterprise (Classic), the repository includes migration guidance in `docs/MIGRATION.md` covering:
- Connection string changes
- Module compatibility 
- Deployment strategies
- Rollback procedures

**Future azurerm support:**
When the azurerm provider adds native Azure Managed Redis support, the module is designed to make migration straightforward - the interface will remain stable while the implementation switches to native resources.

---

## Getting Started Today

**1. Try it instantly:**
[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/tfindelkind-redis/azure-managed-redis-terraform)

**2. Or clone locally:**
```bash
git clone https://github.com/tfindelkind-redis/azure-managed-redis-terraform
cd azure-managed-redis-terraform/examples/simple
terraform init && terraform apply
```

**3. Explore the examples:**
- `simple/` - Basic Redis Enterprise cluster
- `with-modules/` - Redis modules showcase  
- `high-availability/` - HA configuration
- `multi-region/` - Global deployment pattern

---

## Conclusion

Azure Managed Redis brings Redis Enterprise capabilities into Azure's managed service portfolio. While native Terraform support is still in development, the AzAPI provider gives you immediate access to deploy and manage these resources through infrastructure as code.

This module provides:
- **Immediate deployment** capability using AzAPI
- **Working examples** for common scenarios  
- **Testing and validation** scripts
- **Future-ready design** for easy migration to azurerm

The key benefit: you can start automating Azure Managed Redis deployments today without waiting for native provider support.

👉 [**Get started with the module and examples on GitHub**](https://github.com/tfindelkind-redis/azure-managed-redis-terraform)

---

## About the Author

**Thomas Findelkind** is a Developer Advocate at Redis, helping teams architect, automate, and scale with Redis Enterprise in the cloud.  
Follow Thomas on [LinkedIn](https://www.linkedin.com/in/thomasfindelkind) or [GitHub](https://github.com/tfindelkind-redis).
