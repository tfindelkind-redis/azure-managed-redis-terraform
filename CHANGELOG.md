# Changelog

## [Unreleased]

### Added
- Support for new SKU types (validated for future API versions):
  - **Flash Optimized SKUs**: FlashOptimized_A250 through FlashOptimized_A4500
  - **Expanded Balanced SKUs**: Balanced_B10 through Balanced_B1000  
  - **Extended Memory Optimized**: MemoryOptimized_M50 through MemoryOptimized_M2000
  - **Enhanced Compute Optimized**: ComputeOptimized_X20 through ComputeOptimized_X700
- Enhanced SKU validation with comprehensive list of 40+ supported SKU types
- New data source pattern for reading cluster properties post-creation
- Enhanced .gitignore with comprehensive Terraform file patterns (*.out, *.tfstate.backup, crash.log)

### Changed
- **API Version**: Maintained `2024-09-01-preview` after testing newer versions
  - Tested `2025-05-01-preview` and `2025-04-01` - both caused cluster creation failures
  - Reverted to proven stable version `2024-09-01-preview` for reliability
- **Output Structure**: Fixed hostname and connection string outputs using `jsondecode()` pattern
  - Data source outputs return JSON strings, not objects
  - All hostname references now use: `jsondecode(data.azapi_resource.cluster_data[0].output).properties.hostName`
  - Module outputs automatically propagate to all examples
- Expanded SKU validation to include all new SKU types for forward compatibility
- Location format in all examples changed from "East US" to canonical "eastus" format

### Fixed  
- **Output Parsing**: Corrected data source output access pattern with `jsondecode()` for JSON string outputs
- **Deployment Validation**: Full GitHub Actions deployment cycle verified (cluster creation ~7 min, database ~12 sec)
- **Connectivity**: Hostname and connection string outputs validated with live deployment test
- Removed Terraform plan.out files from repository (should not be committed)
- Cleaned up terraform.tfstate and .tfvars files from examples directory

### Testing Notes
- All 4 examples verified to work with module output pattern (pass-through references)
- Successful deployment: `redis-simple-test-20251020095447.eastus.redis.azure.net`
- GitHub Actions workflow: 15m50s total deployment time
- Connectivity test: PASSED
