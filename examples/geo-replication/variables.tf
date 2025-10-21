variable "primary_location" {
  description = "Primary Azure region"
  type        = string
  default     = "northeurope"
}

variable "secondary_location" {
  description = "Secondary Azure region for geo-replication"
  type        = string
  default     = "westeurope"
}

variable "primary_resource_group_name" {
  description = "Primary region resource group name"
  type        = string
  default     = "rg-azure-managed-redis-terraform"
}

variable "secondary_resource_group_name" {
  description = "Secondary region resource group name"
  type        = string
  default     = "rg-azure-managed-redis-terraform2"
}

variable "create_resource_groups" {
  description = "Whether to create new resource groups or use existing ones"
  type        = bool
  default     = true
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "azure-managed-redis-terraform"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "redis_sku" {
  description = "Redis Enterprise SKU for both regions"
  type        = string
  default     = "Balanced_B3"
}

variable "geo_replication_group_name" {
  description = "Nickname for the geo-replication group"
  type        = string
  default     = "azure-managed-redis-geo-group"
}
