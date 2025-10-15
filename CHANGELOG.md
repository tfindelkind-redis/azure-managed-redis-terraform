# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of Azure Managed Redis Terraform module
- AzAPI-based implementation for current deployment
- Future-proof design for native azurerm migration
- Comprehensive examples (simple, with-modules, high-availability, multi-region)
- Complete CI/CD pipeline with automated validation
- Security scanning with tfsec
- Automated provider version management with Renovate
- Nightly validation workflow
- Configurable deployment options

### Features
- Support for all Azure Managed Redis SKUs
- Redis Enterprise modules support (JSON, Search, Bloom, TimeSeries)
- High availability with multi-AZ deployment
- TLS encryption and secure key management
- Comprehensive variable validation
- Detailed output configuration
- Tag-based resource management

### Documentation
- Complete module documentation
- Multiple deployment examples
- Migration guide preparation
- Troubleshooting guide
- CI/CD integration examples

### Infrastructure
- GitHub Actions workflows for CI/CD
- Automated testing and validation
- Security scanning integration
- Documentation automation
- Release management
