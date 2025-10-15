# Azure Managed Redis Terraform Module

This Terraform module provisions Azure Managed Redis (Redis Enterprise) resources using the AzAPI provider, with a future-proof design for seamless migration to native azurerm resources.

## Features

- **Azure Managed Redis Cluster**: Fully managed Redis Enterprise cluster
- **Database Configuration**: Configurable Redis database with modules
- **Security**: TLS encryption and secure access key management
- **High Availability**: Optional high availability configuration
- **Redis Modules**: Support for RedisJSON, RediSearch, RedisBloom, and RedisTimeSeries
- **Future-Proof**: Designed for easy migration to native azurerm when available

## Usage

```hcl
module "redis_enterprise" {
  source = "../../modules/managed-redis"
  
  name                = "my-redis-enterprise"
  resource_group_name = "rg-redis-example"
  location            = "East US"
  sku                 = "Balanced_B1"
  
  modules = [
    "RedisJSON",
    "RediSearch"
  ]
  
  high_availability    = true
  minimum_tls_version = "1.2"
  
  tags = {
    Environment = "production"
    Owner       = "platform-team"
  }
}
```

## Examples

- [Simple Deployment](../../examples/simple/) - Basic Redis Enterprise cluster
- [With Modules](../../examples/with-modules/) - Redis with additional modules
- [High Availability](../../examples/high-availability/) - HA configuration setup
- [Multi-Region](../../examples/multi-region/) - Geo-distributed deployment

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |
| azapi | ~> 1.15 |
| azurerm | ~> 3.80 |

## Providers

| Name | Version |
|------|---------|
| azapi | ~> 1.15 |
| azurerm | ~> 3.80 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | The name of the Redis Enterprise cluster | `string` | n/a | yes |
| resource_group_name | The name of the resource group | `string` | n/a | yes |
| location | The Azure region | `string` | n/a | yes |
| sku | The SKU of the Redis Enterprise cluster | `string` | `"Balanced_B0"` | no |
| modules | List of Redis modules to enable | `list(string)` | `["RedisJSON", "RediSearch"]` | no |
| minimum_tls_version | The minimum TLS version | `string` | `"1.2"` | no |
| high_availability | Enable high availability | `bool` | `true` | no |
| use_azapi | Use AzAPI provider (future: switch to native) | `bool` | `true` | no |
| eviction_policy | Redis eviction policy | `string` | `"NoEviction"` | no |
| client_protocol | Client protocol (Encrypted/Plaintext) | `string` | `"Encrypted"` | no |
| clustering_policy | Clustering policy | `string` | `"EnterpriseCluster"` | no |
| database_name | Name of the Redis database | `string` | `"default"` | no |
| zones | Availability zones | `list(string)` | `[]` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The ID of the Redis Enterprise cluster |
| cluster_name | The name of the Redis Enterprise cluster |
| database_id | The ID of the Redis database |
| database_name | The name of the Redis database |
| hostname | The hostname of the Redis database |
| port | The port of the Redis database |
| primary_key | The primary access key (sensitive) |
| secondary_key | The secondary access key (sensitive) |
| connection_string | Redis connection string (sensitive) |
| connection_string_secondary | Redis connection string with secondary key (sensitive) |

## Available SKUs

- **Balanced**: B0, B1, B3, B5
- **Compute Optimized**: X3, X5, X10  
- **Memory Optimized**: M10, M20
- **Flash**: F300, F700, F1500

## Supported Redis Modules

- **RedisJSON**: JSON data structure support
- **RediSearch**: Full-text search and indexing
- **RedisBloom**: Probabilistic data structures
- **RedisTimeSeries**: Time series data support

## Migration Path

This module is designed for seamless migration:

1. **Today**: Uses AzAPI provider (`use_azapi = true`)
2. **Tomorrow**: Switch to native azurerm (`use_azapi = false`) when available
3. **No breaking changes**: Module interface remains identical

## Security Considerations

- All access keys are marked as sensitive outputs
- TLS encryption is enforced by default
- No temporary files or CLI scripts are used for key retrieval
- Uses Azure API actions for secure credential management

## Contributing

Please see [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines.

## License

This module is licensed under the MIT License. See [LICENSE](../../LICENSE) for details.
