# Deploy Azure Managed Redis with Terraform — AzAPI Today, Native Tomorrow

*By Thomas Findelkind

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


## Available Examples

The repository includes four complete examples to get you started:

```
azure-managed-redis-terraform/
  examples/
    simple/                   # Basic Redis cluster for development
    with-modules/             # Showcase Redis modules (JSON, Search, etc.)  
    high-availability/        # HA configuration for critical workloads
    multi-region/             # Global deployment pattern
```

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

The key benefit: you can start automating Azure Managed Redis deployments today without waiting for native provider support.

👉 [**Get started with the module and examples on GitHub**](https://github.com/tfindelkind-redis/azure-managed-redis-terraform)

---

## About the Author

**Thomas Findelkind** is a Senior Specialist Solution Architect at Redis, helping teams architect, automate, and scale with Redis Enterprise in the cloud.  
Follow Thomas on [LinkedIn](https://www.linkedin.com/in/thomasfindelkind) or [GitHub](https://github.com/tfindelkind-redis).
