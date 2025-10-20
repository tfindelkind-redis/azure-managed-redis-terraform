# Deploy Azure Managed Redis with Terraform — AzAPI Today, Native Tomorrow

*By Thomas Findelkind

> **TL;DR:** Azure Managed Redis is here — a fully managed, Redis Enterprise–powered service. Terraform support is still catching up, but with an AzAPI module, you can deploy today and stay ready for tomorrow's provider updates.

---

## Why Azure Managed Redis?

Azure Managed Redis brings the **power of Redis Enterprise** directly into Azure's control plane. It combines:
- Redis Enterprise's performance, modules, and HA capabilities  
- Azure's managed experience, integrated billing, and security model  

Managed Redis supports modules such as **RedisJSON**, **RediSearch**, and **RedisBloom**, and will expand further as the service matures.

### Azure Cache for Redis Retirement

Microsoft has announced the retirement of **Azure Cache for Redis**, with a clear migration timeline:

- **October 1, 2026**: No new Azure Cache for Redis instances can be created
- **Existing instances**: Will continue to be supported until further notice
- **Recommended path**: Migrate to Azure Managed Redis for new deployments

This makes Azure Managed Redis the **strategic choice** for new Redis deployments on Azure, combining Redis Enterprise capabilities with Azure's managed services approach.

For many teams working with infrastructure as code, this transition means:  
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

### Module Implementation

To demonstrate this AzAPI approach, we've created a comprehensive Terraform module that abstracts the complexity of Azure's REST APIs into a simple, reusable interface. This GitHub repository provides:

- **Reusable Module**: A well-structured Terraform module following best practices
- **Multiple Examples**: Four different deployment scenarios (simple, with-modules, HA, multi-region)
- **Testing Scripts**: Automated validation and connection testing utilities
- **CI/CD Integration**: GitHub Actions workflows for continuous validation
- **Documentation**: Complete usage guides and troubleshooting resources

**Repository**: [tfindelkind-redis/azure-managed-redis-terraform](https://github.com/tfindelkind-redis/azure-managed-redis-terraform)

> ⚠️ **Important Notice**: This repository and module are provided as an informational guide and reference implementation. It is not officially supported by Microsoft, Redis, or any other vendor. Use this content for learning and development purposes, and thoroughly test any implementations before deploying in your environment.

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
variable "zones"               { type = list(string) default = [] }
variable "eviction_policy"     { type = string   default = "NoEviction" }
variable "client_protocol"     { type = string   default = "Encrypted" }
variable "clustering_policy"   { type = string   default = "EnterpriseCluster" }
variable "use_azapi"           { type = bool     default = true }
```

### Outputs
```hcl
# Read cluster properties using data source (required for hostname)
data "azapi_resource" "cluster_data" {
  count                  = var.enable_database ? 1 : 0
  type                   = "${local.redis_enterprise_type}@${local.redis_enterprise_api_version}"
  resource_id            = azapi_resource.cluster.id
  response_export_values = ["properties"]
  depends_on             = [azapi_resource.database]
}

output "cluster_id"    { value = azapi_resource.cluster.id }
output "database_id"   { value = azapi_resource.database.id }
output "hostname"      { value = jsondecode(data.azapi_resource.cluster_data[0].output).properties.hostName }
output "port"          { value = 10000 }
output "primary_key"   { value = jsondecode(data.azapi_resource_action.database_keys.output).primaryKey   sensitive = true }
output "secondary_key" { value = jsondecode(data.azapi_resource_action.database_keys.output).secondaryKey sensitive = true }
```

**Important Note**: The hostname must be retrieved using a data source because it's only available after cluster creation. The data source output returns a JSON string, so `jsondecode()` is required to access nested properties.

This contract remains identical when you later switch to native Terraform resources.

### Why Migration From AzAPI To azurerm Will Be Simple

The module is designed for seamless migration from AzAPI to azurerm because:

- **Identical Interface**: The same input variables and output values work for both implementations
- **Internal Abstraction**: Only the resource implementation changes (from `azapi_resource` to `azurerm_redis_enterprise`)  
- **No State Migration**: Terraform can import existing resources with minimal configuration changes
- **Version Control**: The `use_azapi` variable allows switching implementations without breaking changes

When azurerm adds native support, you simply:
1. Update the module version
2. Set `use_azapi = false` (or leave default)  
3. Run `terraform plan` to see the implementation switch
4. Apply with confidence - same inputs, same outputs, same Redis cluster

---

## Azure Managed Redis Configuration Options

The module supports all major Azure Managed Redis configuration options:

### **Performance & Scaling**
```hcl
# SKU options for different performance tiers
sku = "Balanced_B0"            # Entry level - development
sku = "Balanced_B1"            # Standard workloads  
sku = "Balanced_B5"            # Production workloads
sku = "MemoryOptimized_M10"    # Memory-intensive apps
sku = "FlashOptimized_A250"    # Flash storage for large datasets (new naming)
sku = "EnterpriseFlash_F300"   # Flash storage (legacy naming, still supported)
sku = "ComputeOptimized_X10"   # Compute-intensive workloads
```

### **Security & Networking**  
```hcl
# TLS encryption (always enabled for Azure Managed Redis)
minimum_tls_version = "1.2"    # Recommended minimum
client_protocol = "Encrypted"  # Encrypted (default) or Plaintext

# Note: This module provisions the Redis Enterprise cluster
# For production deployments, configure Azure Private Link separately for enhanced security
# Private endpoints are recommended for production workloads to restrict network access
# Access control is managed through Redis AUTH and Azure RBAC
```

### **High Availability & Reliability**
```hcl 
# Multi-zone deployment
high_availability = true

# Note: Zone redundancy behavior depends on SKU
# - Higher-tier SKUs (e.g., Balanced_B3+) have built-in zone redundancy
#   and don't require (or allow) explicit zones parameter
# - Lower-tier SKUs can optionally specify zones for custom deployment
zones = ["1", "2", "3"]    # Only for SKUs that support explicit zone configuration

# Clustering for horizontal scale
clustering_policy = "EnterpriseCluster"  # Redis Enterprise clustering (default)
clustering_policy = "OSSCluster"         # Open source Redis clustering
```

### **Data Management**
```hcl
# Eviction policies when memory limit reached
eviction_policy = "NoEviction"      # Reject writes (default, required for RediSearch)
eviction_policy = "AllKeysLRU"      # Remove least recently used keys (cache scenarios)
eviction_policy = "VolatileTTL"     # Remove keys with shortest TTL

# Important: RediSearch module requires eviction_policy = "NoEviction"
# For cache use cases without RediSearch, AllKeysLRU is commonly used
```

### **Redis Enterprise Modules**
```hcl
# Advanced Redis capabilities
modules = [
  "RedisJSON",      # JSON document storage
  "RediSearch",     # Full-text search and indexing
  "RedisBloom",     # Probabilistic data structures  
  "RedisTimeSeries" # Time-series data management
]
```
---

## Implementation: **AzAPI (Today)**

Since the `azurerm` provider doesn't yet expose Managed Redis resources, we use `azapi_resource`.

### Cluster
```hcl
resource "azapi_resource" "cluster" {
  type      = "Microsoft.Cache/redisEnterprise@2024-09-01-preview"
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
  zones = var.zones
  schema_validation_enabled = false
}
```

### Database
```hcl
resource "azapi_resource" "database" {
  type      = "Microsoft.Cache/redisEnterprise/databases@2024-09-01-preview"
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
data "azapi_resource_action" "database_keys" {
  type        = "Microsoft.Cache/redisEnterprise/databases@2024-09-01-preview"
  resource_id = azapi_resource.database.id
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

## Testing Your Deployment

After deployment, validate your Redis cluster with the included testing scripts:

```bash
# Test basic connectivity and operations
./scripts/test-connection.sh

# Validate deployment configuration
./scripts/validate-deployment.sh
```

Or test manually:
```bash
# Basic PING test
redis-cli -h myredis.eastus.redisenterprise.cache.azure.net -p 10000 -a <password> ping

# Test RedisJSON module
redis-cli -h myredis.eastus.redisenterprise.cache.azure.net -p 10000 -a <password> \
  JSON.SET user:123 $ '{"name":"John","age":30}'

# Test RediSearch module  
redis-cli -h myredis.eastus.redisenterprise.cache.azure.net -p 10000 -a <password> \
  FT.CREATE idx:users ON JSON PREFIX 1 user: SCHEMA $.name TEXT
```

For visual management, use [RedisInsight](https://redis.io/insight/) with your connection details.

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

Azure Managed Redis brings Redis Enterprise capabilities into Azure's managed service portfolio with:

- **Redis Enterprise modules** (JSON, Search, Bloom, TimeSeries) 
- **Managed scaling** from development to high-performance tiers
- **Built-in high availability** across availability zones
- **Enterprise security** with TLS encryption and Redis AUTH

While native Terraform azurerm support is in development, the AzAPI approach gives you immediate access to all these capabilities through infrastructure as code.

**Key advantages of this approach:**
- Deploy today without waiting for provider updates
- Future-proof design for seamless migration to azurerm  
- Complete configuration coverage (SKUs, modules, HA, security)
- Working examples for common deployment scenarios
- Automated testing and validation

The module handles the complexity of Azure's REST APIs while maintaining the simplicity of Terraform's declarative syntax.

👉 [**Get started with the module and examples on GitHub**](https://github.com/tfindelkind-redis/azure-managed-redis-terraform)

---

## About the Author

**Thomas Findelkind** is a Senior Specialist Solution Architect at Redis, helping teams architect, automate, and scale with Redis Enterprise in the cloud.  
Follow Thomas on [LinkedIn](https://www.linkedin.com/in/thomasfindelkind) 
