variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "redis_name" {
  description = "Name of the Redis cluster"
  type        = string
}

variable "sku_name" {
  description = "SKU name for Redis cluster"
  type        = string
  default     = "Balanced_B3"
}

variable "use_azapi" {
  description = "Use AzAPI provider (required for persistence features)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Example     = "clusterless-with-persistence"
    ManagedBy   = "Terraform"
    Environment = "Development"
  }
}
