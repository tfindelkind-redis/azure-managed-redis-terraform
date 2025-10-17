variable "resource_group_name" {
  description = "Name of the resource group to create the Redis Enterprise cluster in"
  type        = string
  default     = "rg-azure-managed-redis-terraform"
}

variable "location" {
  description = "Azure region for the Redis Enterprise cluster"
  type        = string
  default     = "East US"
}

variable "redis_name" {
  description = "Name of the Redis Enterprise cluster"
  type        = string
  default     = "redis-with-modules"
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
  default     = "development"
}

variable "enable_all_modules" {
  description = "Enable all available Redis modules"
  type        = bool
  default     = true
}

variable "create_resource_group" {
  description = "Whether to create a new resource group or use an existing one"
  type        = bool
  default     = true
}
