variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-redis-enterprise-security"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "northeurope"
}

variable "redis_name" {
  description = "Name of the Redis Enterprise cluster"
  type        = string
  default     = "redis-enterprise-secure"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "sku_name" {
  description = "Redis Managed SKU (Balanced_B3 or higher for HA and CMK support)"
  type        = string
  default     = "Balanced_B3"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "redis_subnet_prefix" {
  description = "Address prefix for Redis private endpoint subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "zones" {
  description = "Availability zones for high availability"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "minimum_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "1.2"
}

variable "enable_modules" {
  description = "Enable Redis modules (JSON, Search)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    "Example"     = "enterprise-security"
    "Managed-By"  = "terraform"
    "Environment" = "production"
    "Security"    = "enhanced"
  }
}
