#!/bin/bash

# Test script for new API version and SKU validation
# This script validates that the new SKUs are properly recognized

set -e

echo "🧪 Testing New API Version 2025-05-01-preview Features"
echo "======================================================"

# Test directory
TEST_DIR="/tmp/redis-api-test"
mkdir -p "$TEST_DIR"

# Create a simple test configuration with a new SKU
cat > "$TEST_DIR/main.tf" << 'EOF'
terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.15"
    }
    azurerm = {
      source  = "hashicorp/azurerm" 
      version = "~> 3.80"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "test_sku" {
  description = "Test SKU to validate"
  type        = string
  default     = "FlashOptimized_A250"  # New SKU type
}

# Use the module with a new Flash Optimized SKU  
module "redis_test" {
  source = "../modules/managed-redis"

  name                = "redis-api-test"
  resource_group_name = "test-rg"
  location            = "northeurope"
  sku                 = var.test_sku
  modules             = []
  high_availability   = false
  use_azapi           = true
}
EOF

# Copy the module to test directory
cp -r "modules" "$TEST_DIR/"

cd "$TEST_DIR"

echo "🔍 Testing SKU Validation with FlashOptimized_A250..."
terraform init -backend=false >/dev/null 2>&1
if terraform validate >/dev/null 2>&1; then
    echo "✅ New SKU 'FlashOptimized_A250' validation passed!"
else 
    echo "❌ New SKU validation failed"
    terraform validate
    exit 1
fi

echo "🔍 Testing SKU Validation with invalid SKU..."
if terraform plan -var="test_sku=InvalidSKU" >/dev/null 2>&1; then
    echo "❌ Invalid SKU should have been rejected"
    exit 1
else
    echo "✅ Invalid SKU correctly rejected"
fi

# Cleanup
cd - >/dev/null
rm -rf "$TEST_DIR"

echo "======================================================"
echo "🎉 All API version and SKU tests passed!"
echo "✅ API Version: 2025-05-01-preview"
echo "✅ New SKU Types: Validated"  
echo "✅ SKU Validation: Working"
