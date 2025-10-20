variable "resource_group_name" {
  description = "Name of the resource group to create the Redis Enterprise cluster in"
  type        = string
  default     = "rg-azure-managed-redis-terraform"
}

variable "location" {
  description = "Azure region for the Redis Enterprise cluster"
  type        = string
  default     = "eastus"
}

variable "redis_name" {
  description = "Name of the Redis Enterprise cluster"
  type        = string
  default     = "redis-production"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "availability_zones" {
  description = "Availability zones to deploy across"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "business_unit" {
  description = "Business unit for cost allocation"
  type        = string
  default     = "platform"
}

variable "create_resource_group" {
  description = "Whether to create a new resource group or use an existing one"
  type        = bool
  default     = true
}
