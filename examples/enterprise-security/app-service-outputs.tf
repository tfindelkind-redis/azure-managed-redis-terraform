# App Service outputs
output "app_service_url" {
  description = "URL of the Redis testing application"
  value       = "https://${azurerm_linux_web_app.redis_test.default_hostname}"
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = azurerm_linux_web_app.redis_test.name
}

output "api_key_secret_name" {
  description = "Name of the API key secret in Key Vault"
  value       = azurerm_key_vault_secret.api_key.name
}

output "api_key_command" {
  description = "Command to retrieve the API key"
  value       = "az keyvault secret show --vault-name ${azurerm_key_vault.redis.name} --name ${azurerm_key_vault_secret.api_key.name} --query value -o tsv"
}

output "application_insights_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.redis_test.instrumentation_key
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for monitoring"
  value       = azurerm_log_analytics_workspace.redis.id
}

output "app_deployment_status" {
  description = "Status of the application deployment"
  value       = "✅ App deployed automatically via Terraform. Check health at: https://${azurerm_linux_web_app.redis_test.default_hostname}/api/health"
  depends_on  = [null_resource.deploy_app]
}

output "app_test_commands" {
  description = "Commands to test the deployed application"
  value = <<-EOT
    # Test health endpoint
    curl https://${azurerm_linux_web_app.redis_test.default_hostname}/api/health
    
    # Get API key from Key Vault
    API_KEY=$(az keyvault secret show --vault-name ${azurerm_key_vault.redis.name} --name api-key --query value -o tsv)
    
    # Test Redis connectivity (requires API key in header)
    curl -H "X-API-Key: $API_KEY" https://${azurerm_linux_web_app.redis_test.default_hostname}/api/redis/ping
  EOT
}
