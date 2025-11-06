<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | ~> 2.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.50 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | 2.7.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.51.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azapi_resource.cluster](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.database](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azurerm_managed_redis.cluster](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_redis) | resource |
| [azapi_resource.cluster_data](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource) | data source |
| [azapi_resource_action.database_keys](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource_action) | data source |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_keys_authentication_enabled"></a> [access\_keys\_authentication\_enabled](#input\_access\_keys\_authentication\_enabled) | Enable access keys authentication | `bool` | `true` | no |
| <a name="input_client_protocol"></a> [client\_protocol](#input\_client\_protocol) | Client protocol for the Redis database | `string` | `"Encrypted"` | no |
| <a name="input_clustering_policy"></a> [clustering\_policy](#input\_clustering\_policy) | Clustering policy for the Redis database.<br/>- EnterpriseCluster: Single endpoint with proxy routing (required for RediSearch)<br/>- OSSCluster: Redis Cluster API with direct shard connections (best performance)<br/>- NoCluster: True non-clustered mode, no sharding (≤25 GB only, Preview) | `string` | `"EnterpriseCluster"` | no |
| <a name="input_customer_managed_key_enabled"></a> [customer\_managed\_key\_enabled](#input\_customer\_managed\_key\_enabled) | Enable Customer Managed Key (CMK) encryption. Supported by both AzAPI and AzureRM providers. | `bool` | `false` | no |
| <a name="input_customer_managed_key_identity_id"></a> [customer\_managed\_key\_identity\_id](#input\_customer\_managed\_key\_identity\_id) | The User Assigned Identity ID to use for accessing the Customer Managed Key. Supported by both AzAPI and AzureRM providers. | `string` | `null` | no |
| <a name="input_customer_managed_key_vault_key_id"></a> [customer\_managed\_key\_vault\_key\_id](#input\_customer\_managed\_key\_vault\_key\_id) | The Key Vault Key ID for Customer Managed Key encryption. Supported by both AzAPI and AzureRM providers. | `string` | `null` | no |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | Name of the Redis database within the cluster | `string` | `"default"` | no |
| <a name="input_defer_upgrade"></a> [defer\_upgrade](#input\_defer\_upgrade) | Whether to defer upgrade. Valid values: NotDeferred, Deferred | `string` | `"NotDeferred"` | no |
| <a name="input_eviction_policy"></a> [eviction\_policy](#input\_eviction\_policy) | Redis eviction policy for the database | `string` | `"NoEviction"` | no |
| <a name="input_geo_replication_enabled"></a> [geo\_replication\_enabled](#input\_geo\_replication\_enabled) | Enable geo-replication for this database | `bool` | `false` | no |
| <a name="input_geo_replication_group_nickname"></a> [geo\_replication\_group\_nickname](#input\_geo\_replication\_group\_nickname) | The nickname for the geo-replication group | `string` | `""` | no |
| <a name="input_geo_replication_linked_database_ids"></a> [geo\_replication\_linked\_database\_ids](#input\_geo\_replication\_linked\_database\_ids) | List of linked database IDs for geo-replication. Include this database's ID and all other databases in the replication group. | `list(string)` | `[]` | no |
| <a name="input_high_availability"></a> [high\_availability](#input\_high\_availability) | Enable high availability for the Redis Enterprise cluster | `bool` | `true` | no |
| <a name="input_identity_ids"></a> [identity\_ids](#input\_identity\_ids) | List of User Assigned Managed Identity IDs. Required when identity\_type includes 'UserAssigned'. Supported by both AzAPI and AzureRM providers. | `list(string)` | `[]` | no |
| <a name="input_identity_type"></a> [identity\_type](#input\_identity\_type) | Type of managed identity. Options: null (none), 'SystemAssigned', 'UserAssigned', 'SystemAssigned, UserAssigned'. Supported by both AzAPI and AzureRM providers. | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | The Azure region in which to create the Redis Enterprise cluster | `string` | n/a | yes |
| <a name="input_minimum_tls_version"></a> [minimum\_tls\_version](#input\_minimum\_tls\_version) | The minimum TLS version for the Redis Enterprise cluster | `string` | `"1.2"` | no |
| <a name="input_modules"></a> [modules](#input\_modules) | List of Redis modules to enable | `list(string)` | <pre>[<br/>  "RedisJSON",<br/>  "RediSearch"<br/>]</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Redis Enterprise cluster | `string` | n/a | yes |
| <a name="input_persistence_aof_enabled"></a> [persistence\_aof\_enabled](#input\_persistence\_aof\_enabled) | Enable AOF persistence | `bool` | `false` | no |
| <a name="input_persistence_rdb_enabled"></a> [persistence\_rdb\_enabled](#input\_persistence\_rdb\_enabled) | Enable RDB persistence | `bool` | `false` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group in which to create the Redis Enterprise cluster | `string` | n/a | yes |
| <a name="input_sku"></a> [sku](#input\_sku) | The SKU of the Redis Enterprise cluster | `string` | `"Balanced_B0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the Redis Enterprise resources | `map(string)` | `{}` | no |
| <a name="input_use_azapi"></a> [use\_azapi](#input\_use\_azapi) | Use AzAPI provider instead of native azurerm (when available) | `bool` | `true` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | Availability zones for the Redis Enterprise cluster | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | The ID of the Redis Enterprise cluster |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | The name of the Redis Enterprise cluster |
| <a name="output_connection_string"></a> [connection\_string](#output\_connection\_string) | Redis connection string (null if access keys are disabled) |
| <a name="output_connection_string_secondary"></a> [connection\_string\_secondary](#output\_connection\_string\_secondary) | Redis connection string using secondary key (null if access keys are disabled) |
| <a name="output_database_id"></a> [database\_id](#output\_database\_id) | The ID of the Redis database |
| <a name="output_database_name"></a> [database\_name](#output\_database\_name) | The name of the Redis database |
| <a name="output_high_availability_enabled"></a> [high\_availability\_enabled](#output\_high\_availability\_enabled) | Whether high availability is enabled for the cluster |
| <a name="output_hostname"></a> [hostname](#output\_hostname) | The hostname of the Redis database |
| <a name="output_location"></a> [location](#output\_location) | The Azure region of the Redis Enterprise cluster |
| <a name="output_minimum_tls_version"></a> [minimum\_tls\_version](#output\_minimum\_tls\_version) | The minimum TLS version configured for the cluster |
| <a name="output_modules"></a> [modules](#output\_modules) | List of Redis modules enabled on the database |
| <a name="output_port"></a> [port](#output\_port) | The port of the Redis database |
| <a name="output_primary_key"></a> [primary\_key](#output\_primary\_key) | The primary access key for the Redis database (null if access keys are disabled) |
| <a name="output_redis_cli_command"></a> [redis\_cli\_command](#output\_redis\_cli\_command) | Redis CLI command to connect to the database |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | The name of the resource group containing the Redis resources |
| <a name="output_secondary_key"></a> [secondary\_key](#output\_secondary\_key) | The secondary access key for the Redis database (null if access keys are disabled) |
| <a name="output_sku"></a> [sku](#output\_sku) | The SKU of the Redis Enterprise cluster |
| <a name="output_test_connection_info"></a> [test\_connection\_info](#output\_test\_connection\_info) | Information for testing the Redis connection |
<!-- END_TF_DOCS -->