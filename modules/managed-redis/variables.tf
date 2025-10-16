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
      "Balanced_B0", "Balanced_B1", "Balanced_B3", "Balanced_B5",
      "ComputeOptimized_X3", "ComputeOptimized_X5", "ComputeOptimized_X10",
      "MemoryOptimized_M10", "MemoryOptimized_M20",
      "Flash_F300", "Flash_F700", "Flash_F1500"
    ], var.sku)
    error_message = "SKU must be a valid Azure Managed Redis SKU."
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
  description = "Clustering policy for the Redis database"
  type        = string
  default     = "EnterpriseCluster"

  validation {
    condition     = contains(["EnterpriseCluster", "OSSCluster"], var.clustering_policy)
    error_message = "Clustering policy must be either 'EnterpriseCluster' or 'OSSCluster'."
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
