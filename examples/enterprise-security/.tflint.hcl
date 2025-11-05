# TFLint Configuration for enterprise-security example
#
# This example intentionally uses a non-standard structure for better organization:
# - app-service-outputs.tf: Contains outputs specific to the deployed test application
# - outputs.tf: Contains outputs specific to Redis infrastructure
#
# This separation improves readability and maintainability for this complex example.

config {
  call_module_type = "none"
  force = false
}

plugin "terraform" {
  enabled = true
  preset  = "all"
}

plugin "azurerm" {
  enabled = true
}

# Disable standard module structure rule for this example
# We intentionally split outputs into multiple files for organization
rule "terraform_standard_module_structure" {
  enabled = false
}
