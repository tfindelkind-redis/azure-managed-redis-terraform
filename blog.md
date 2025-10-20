# Deploy Azure Managed Redis with Terraform — AzAPI Today, Native Tomorrow

> **TL;DR:** Azure Managed Redis is here — a fully managed, Redis Enterprise–powered service. Terraform support is still catching up, but with an AzAPI module, you can deploy today and stay ready for tomorrow's provider updates.

---

## Why Azure Managed Redis?

Azure Managed Redis brings the **power of Redis Enterprise** directly into Azure's control plane. It combines:
- Redis Enterprise's performance, modules, and HA capabilities  
- Azure's managed experience, integrated billing, and security model  

Managed Redis supports modules such as **RedisJSON**, **RediSearch**, **RedisBloom** and **RedisTimeSeries** will expand further as the service matures.

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
3. Optional **Modules** (RedisJSON, RediSearch, RedisBloom, RedisTimeSeries)  
4. **Access keys** managed securely through Azure APIs  

Terraform provisions both cluster and database layers using the AzAPI provider — for now — until `azurerm` gains full native support.

---

## Terraform Module Interface

### Inputs (Key Variables)
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
variable "database_name"       { type = string   default = "default" }
variable "port"                { type = number   default = 10000 }
variable "use_azapi"           { type = bool     default = true }
variable "tags"                { type = map(string) default = {} }
```

> **Note**: This shows the most commonly used variables. See the [full module documentation](https://github.com/tfindelkind-redis/azure-managed-redis-terraform/tree/main/modules/managed-redis) for all available options.

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

output "cluster_id"  { value = azapi_resource.cluster[0].id }
output "database_id" { value = azapi_resource.database[0].id }

# Hostname requires jsondecode() because data.azapi_resource returns JSON string
output "hostname" { 
  value = jsondecode(data.azapi_resource.cluster_data[0].output).properties.hostName 
}

output "port" { value = 10000 }

# Keys use direct property access (azapi_resource_action returns parsed objects)
output "primary_key" { 
  value     = data.azapi_resource_action.database_keys[0].output.primaryKey
  sensitive = true 
}

output "secondary_key" { 
  value     = data.azapi_resource_action.database_keys[0].output.secondaryKey
  sensitive = true 
}
```

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

# Note: Zone redundancy behavior is SKU-dependent
# - Higher-tier SKUs (Balanced_B3+, MemoryOptimized_M*, etc.) have AUTOMATIC zone redundancy
#   These SKUs will REJECT deployment if you specify an explicit zones parameter
# - Lower-tier SKUs (Balanced_B0, B1) can optionally specify explicit zones
# - Best practice: Use high_availability = true and omit zones parameter

# Only specify zones for lower-tier SKUs that support explicit zone configuration:
# zones = ["1", "2", "3"]    # Use ONLY with Balanced_B0/B1 or similar lower-tier SKUs

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
locals {
  # Using 2025-05-01-preview to showcase new parameters like deferUpgrade and Azure Portal is using it atm
  # Feel free to revert back to ""2025-05-01" and remove deferUpgrade and persistence
  redis_enterprise_api_version = "2025-05-01-preview"
}

resource "azapi_resource" "cluster" {
  count     = var.use_azapi ? 1 : 0
  type      = "Microsoft.Cache/redisEnterprise@${local.redis_enterprise_api_version}"
  name      = var.name
  location  = var.location
  parent_id = var.resource_group_id
  
  body = jsonencode({
    sku = {
      name = var.sku
    }
    properties = {
      minimumTlsVersion = var.minimum_tls_version
    }
  })
  
  # Note: Do NOT specify zones for higher-tier SKUs (B3+) - they have automatic zone redundancy
  # Uncomment only for lower-tier SKUs that support explicit zones:
  # zones = var.zones
  
  tags                      = var.tags
  schema_validation_enabled = false
  
  timeouts {
    create = "20m"
    delete = "20m"
  }
}
```

### Database
```hcl
resource "azapi_resource" "database" {
  count     = var.use_azapi ? 1 : 0
  type      = "Microsoft.Cache/redisEnterprise/databases@${local.redis_enterprise_api_version}"
  name      = var.database_name
  parent_id = azapi_resource.cluster[0].id
  
  body = jsonencode({
    properties = {
      clientProtocol   = var.client_protocol
      evictionPolicy   = var.eviction_policy
      clusteringPolicy = var.clustering_policy
      port             = var.port
      modules          = [for m in var.modules : { name = m }]
      
      # Required properties for API version 2025-05-01-preview
      deferUpgrade = "NotDeferred"
      
      # Must be "Enabled" for Terraform to use listKeys operation
      # Note: Portal deployments may use "Disabled" but Terraform requires "Enabled"
      accessKeysAuthentication = "Enabled"
      
      persistence = {
        aofEnabled = false
        rdbEnabled = false
      }
    }
  })
  
  depends_on = [azapi_resource.cluster]
  
  timeouts {
    create = "15m"
    delete = "20m"
  }
}
```

> **Important Notes**: 
> - When using RediSearch module, `eviction_policy` must be set to `"NoEviction"`
> - `accessKeysAuthentication` must be `"Enabled"` for Terraform to retrieve keys via the listKeys API
> - Portal deployments may use `"Disabled"` for this setting, but Terraform automation requires `"Enabled"`

### Access Keys (no scripts needed)
```hcl
data "azapi_resource_action" "database_keys" {
  type        = "Microsoft.Cache/redisEnterprise/databases@${local.redis_enterprise_api_version}"
  resource_id = azapi_resource.database.id
  action      = "listKeys"
  method      = "POST"
  response_export_values = ["primaryKey", "secondaryKey"]
}
```

This calls Azure's documented **List Keys** API action — no `null_resource`, no local scripts, just clean data source logic.

> **Note**: The listKeys operation requires `accessKeysAuthentication = "Enabled"` in the database configuration. This is why Terraform deployments differ slightly from portal ARM templates that may use `"Disabled"`.

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
# Using connection URL format (recommended - handles TLS automatically)
redis-cli -u "rediss://:<password>@myredis.eastus.redisenterprise.cache.azure.net:10000" ping

# Or with explicit TLS flag
redis-cli -h myredis.eastus.redisenterprise.cache.azure.net -p 10000 --tls -a <password> ping

# Test RedisJSON module
redis-cli -u "rediss://:<password>@myredis.eastus.redisenterprise.cache.azure.net:10000" \
  JSON.SET user:123 $ '{"name":"John","age":30}'

redis-cli -u "rediss://:<password>@myredis.eastus.redisenterprise.cache.azure.net:10000" \
  JSON.GET user:123

# Test RediSearch module (requires eviction_policy = "NoEviction")
redis-cli -u "rediss://:<password>@myredis.eastus.redisenterprise.cache.azure.net:10000" \
  FT.CREATE idx:users ON JSON PREFIX 1 user: SCHEMA $.name TEXT

redis-cli -u "rediss://:<password>@myredis.eastus.redisenterprise.cache.azure.net:10000" \
  FT.SEARCH idx:users '*'
```

> **Note**: Azure Managed Redis uses TLS encryption by default. Always use `rediss://` (with double 's') in connection URLs or `--tls` flag with redis-cli.

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
