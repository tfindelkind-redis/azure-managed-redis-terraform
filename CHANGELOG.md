# Changelog

## [Unreleased]

### Added
- Updated Azure Redis Enterprise API version to `2025-05-01-preview`
- Support for new SKU types:
  - **Flash Optimized SKUs**: FlashOptimized_A250 through FlashOptimized_A4500
  - **Expanded Balanced SKUs**: Balanced_B10 through Balanced_B1000  
  - **Extended Memory Optimized**: MemoryOptimized_M50 through MemoryOptimized_M2000
  - **Enhanced Compute Optimized**: ComputeOptimized_X20 through ComputeOptimized_X700
- Enhanced SKU validation with comprehensive list of supported SKU types
- New API features: `kind` property and `redundancyMode` status
- Support for `listSkusForScaling` function for dynamic SKU management

### Changed
- API version updated from `2024-09-01-preview` to `2025-05-01-preview`
- Expanded SKU validation to include all new SKU types
- Updated documentation to reflect new API capabilities

### Fixed  
- Location format in all examples changed from "East US" to canonical "eastus" format
- All examples tested and validated with new API version
- Removed Terraform plan.out files from repository (should not be committed)
- Enhanced .gitignore with comprehensive Terraform file patterns
- Cleaned up terraform.tfstate and .tfvars files from examples directory
