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
  description = "Name of the Redis Enterprise cluster. Note: Key Vault names are limited to 24 characters, so names >21 chars will be truncated and modified."
  type        = string
  default     = "redis-enterprise-secure"
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

# ============================================================================
# Provider Configuration
# ============================================================================
# Provider Selection
# ============================================================================
# Note: The main Redis module supports both azurerm and azapi providers.
# However, access policy assignments ALWAYS require azapi for Terraform users
# (they work natively in Bicep/ARM).

variable "use_azapi" {
  description = "Use AzAPI provider instead of AzureRM for Redis cluster/database resources. Access policy assignments always require AzAPI for Terraform (azurerm doesn't support this resource type yet)."
  type        = bool
  default     = true
}

# ============================================================================
# BYOK (Bring Your Own Key) Configuration
# ============================================================================

variable "use_byok" {
  description = "Enable Bring Your Own Key (BYOK) for encryption. If true, imports a user-provided key. If false, Azure generates the key."
  type        = bool
  default     = false
}

variable "byok_key_file_path" {
  description = "Path to the PEM file containing the encryption key (relative to module path). Required when use_byok = true."
  type        = string
  default     = "redis-encryption-key.pem"

  validation {
    condition     = can(regex("\\.(pem|key)$", var.byok_key_file_path))
    error_message = "Key file must have .pem or .key extension."
  }
}
