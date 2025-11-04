variable "name" {
  description = "The name of the Redis Enterprise cluster"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.name))
    error_message = "Name must be between 3 and 63 characters, start and end with alphanumeric characters, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Redis Enterprise cluster"
  type        = string
}

variable "location" {
  description = "The Azure region in which to create the Redis Enterprise cluster"
  type        = string
}

variable "sku" {
  description = "The SKU of the Redis Enterprise cluster"
  type        = string
  default     = "Balanced_B0"

  validation {
    condition = contains([
      # Enterprise SKUs
      "Enterprise_E1", "Enterprise_E5", "Enterprise_E10", "Enterprise_E20",
      "Enterprise_E50", "Enterprise_E100", "Enterprise_E200", "Enterprise_E400",
      # Enterprise Flash SKUs
      "EnterpriseFlash_F300", "EnterpriseFlash_F700", "EnterpriseFlash_F1500",
      # Balanced SKUs (new expanded range)
      "Balanced_B0", "Balanced_B1", "Balanced_B3", "Balanced_B5", "Balanced_B10",
      "Balanced_B20", "Balanced_B50", "Balanced_B100", "Balanced_B150",
      "Balanced_B250", "Balanced_B350", "Balanced_B500", "Balanced_B700", "Balanced_B1000",
      # Memory Optimized SKUs (greatly expanded)
      "MemoryOptimized_M10", "MemoryOptimized_M20", "MemoryOptimized_M50",
      "MemoryOptimized_M100", "MemoryOptimized_M150", "MemoryOptimized_M250",
      "MemoryOptimized_M350", "MemoryOptimized_M500", "MemoryOptimized_M700",
      "MemoryOptimized_M1000", "MemoryOptimized_M1500", "MemoryOptimized_M2000",
      # Compute Optimized SKUs (expanded)
      "ComputeOptimized_X3", "ComputeOptimized_X5", "ComputeOptimized_X10",
      "ComputeOptimized_X20", "ComputeOptimized_X50", "ComputeOptimized_X100",
      "ComputeOptimized_X150", "ComputeOptimized_X250", "ComputeOptimized_X350",
      "ComputeOptimized_X500", "ComputeOptimized_X700",
      # Flash Optimized SKUs (completely new!)
      "FlashOptimized_A250", "FlashOptimized_A500", "FlashOptimized_A700",
      "FlashOptimized_A1000", "FlashOptimized_A1500", "FlashOptimized_A2000",
      "FlashOptimized_A4500"
    ], var.sku)
    error_message = "SKU must be a valid Azure Redis Enterprise SKU. See https://docs.microsoft.com/en-us/azure/azure-cache-for-redis/cache-overview#service-tiers for valid options."
  }
}

variable "modules" {
  description = "List of Redis modules to enable"
  type        = list(string)
  default     = ["RedisJSON", "RediSearch"]

  validation {
    condition = alltrue([
      for module in var.modules : contains([
        "RedisJSON", "RediSearch", "RedisBloom", "RedisTimeSeries", "RediSearch"
      ], module)
    ])
    error_message = "All modules must be valid Redis Enterprise modules: RedisJSON, RediSearch, RedisBloom, RedisTimeSeries."
  }
}

variable "minimum_tls_version" {
  description = "The minimum TLS version for the Redis Enterprise cluster"
  type        = string
  default     = "1.2"

  validation {
    condition     = contains(["1.0", "1.1", "1.2"], var.minimum_tls_version)
    error_message = "Minimum TLS version must be 1.0, 1.1, or 1.2."
  }
}

variable "high_availability" {
  description = "Enable high availability for the Redis Enterprise cluster"
  type        = bool
  default     = true
}

variable "use_azapi" {
  description = "Use AzAPI provider instead of native azurerm (when available)"
  type        = bool
  default     = true
}

variable "eviction_policy" {
  description = "Redis eviction policy for the database"
  type        = string
  default     = "NoEviction"

  validation {
    condition = contains([
      "NoEviction", "AllKeysLRU", "AllKeysRandom", "VolatileLRU",
      "VolatileRandom", "VolatileTTL", "AllKeysLFU", "VolatileLFU"
    ], var.eviction_policy)
    error_message = "Eviction policy must be a valid Redis eviction policy."
  }
}

variable "client_protocol" {
  description = "Client protocol for the Redis database"
  type        = string
  default     = "Encrypted"

  validation {
    condition     = contains(["Encrypted", "Plaintext"], var.client_protocol)
    error_message = "Client protocol must be either 'Encrypted' or 'Plaintext'."
  }
}

variable "clustering_policy" {
  description = <<-EOT
    Clustering policy for the Redis database.
    - EnterpriseCluster: Single endpoint with proxy routing (required for RediSearch)
    - OSSCluster: Redis Cluster API with direct shard connections (best performance)
    - NoCluster: True non-clustered mode, no sharding (≤25 GB only, Preview)
  EOT
  type        = string
  default     = "EnterpriseCluster"

  validation {
    condition     = contains(["EnterpriseCluster", "OSSCluster", "NoCluster"], var.clustering_policy)
    error_message = "Clustering policy must be 'EnterpriseCluster', 'OSSCluster', or 'NoCluster'."
  }
}

variable "database_name" {
  description = "Name of the Redis database within the cluster"
  type        = string
  default     = "default"
}

variable "zones" {
  description = "Availability zones for the Redis Enterprise cluster"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to the Redis Enterprise resources"
  type        = map(string)
  default     = {}
}

variable "geo_replication_enabled" {
  description = "Enable geo-replication for this database"
  type        = bool
  default     = false
}

variable "geo_replication_group_nickname" {
  description = "The nickname for the geo-replication group"
  type        = string
  default     = ""
}

variable "geo_replication_linked_database_ids" {
  description = "List of linked database IDs for geo-replication. Include this database's ID and all other databases in the replication group."
  type        = list(string)
  default     = []
}

variable "persistence_aof_enabled" {
  description = "Enable AOF persistence"
  type        = bool
  default     = false
}

variable "persistence_rdb_enabled" {
  description = "Enable RDB persistence"
  type        = bool
  default     = false
}

variable "access_keys_authentication_enabled" {
  description = "Enable access keys authentication"
  type        = bool
  default     = true
}

variable "defer_upgrade" {
  description = "Whether to defer upgrade. Valid values: NotDeferred, Deferred"
  type        = string
  default     = "NotDeferred"

  validation {
    condition     = contains(["NotDeferred", "Deferred"], var.defer_upgrade)
    error_message = "defer_upgrade must be either 'NotDeferred' or 'Deferred'."
  }
}

# Managed Identity and Encryption features (supported by both AzAPI and AzureRM)
variable "identity_type" {
  description = "Type of managed identity. Options: null (none), 'SystemAssigned', 'UserAssigned', 'SystemAssigned, UserAssigned'. Supported by both AzAPI and AzureRM providers."
  type        = string
  default     = null

  validation {
    condition     = var.identity_type == null ? true : contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
    error_message = "identity_type must be null, 'SystemAssigned', 'UserAssigned', or 'SystemAssigned, UserAssigned'."
  }
}

variable "identity_ids" {
  description = "List of User Assigned Managed Identity IDs. Required when identity_type includes 'UserAssigned'. Supported by both AzAPI and AzureRM providers."
  type        = list(string)
  default     = []
}

variable "customer_managed_key_enabled" {
  description = "Enable Customer Managed Key (CMK) encryption. Supported by both AzAPI and AzureRM providers."
  type        = bool
  default     = false
}

variable "customer_managed_key_vault_key_id" {
  description = "The Key Vault Key ID for Customer Managed Key encryption. Supported by both AzAPI and AzureRM providers."
  type        = string
  default     = null
}

variable "customer_managed_key_identity_id" {
  description = "The User Assigned Identity ID to use for accessing the Customer Managed Key. Supported by both AzAPI and AzureRM providers."
  type        = string
  default     = null
}
