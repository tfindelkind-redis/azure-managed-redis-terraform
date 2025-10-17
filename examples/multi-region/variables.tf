variable "primary_location" {
  description = "Primary Azure region"
  type        = string
  default     = "East US"
}

variable "secondary_location" {
  description = "Secondary Azure region for geo-replication"
  type        = string
  default     = "West Europe"
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
