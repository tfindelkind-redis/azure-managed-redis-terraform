# App Service Plan for Redis Testing App
resource "azurerm_service_plan" "redis_test" {
  name                = "plan-${var.redis_name}-test"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "S1"

  tags = merge(var.tags, {
    "Purpose" = "Redis Testing Application"
  })
}

# App Service for Redis Testing
resource "azurerm_linux_web_app" "redis_test" {
  name                = "app-${var.redis_name}-test-${random_integer.suffix.result}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  service_plan_id     = azurerm_service_plan.redis_test.id

  site_config {
    always_on = true

    application_stack {
      python_version = "3.11"
    }

    # Enable VNet integration for Private Link access
    vnet_route_all_enabled = true

    # Health check endpoint
    health_check_path                 = "/api/health"
    health_check_eviction_time_in_min = 10

    # CORS configuration
    cors {
      allowed_origins     = ["*"] # Restrict this in production
      support_credentials = false
    }
  }

  # VNet Integration
  virtual_network_subnet_id = azurerm_subnet.app_service.id

  # Application Settings
  app_settings = {
    # Redis Configuration
    "REDIS_HOSTNAME"     = module.redis_enterprise.hostname
    "REDIS_PORT"         = tostring(module.redis_enterprise.port)
    "REDIS_PASSWORD"     = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.redis_password.id})"
    "REDIS_SSL"          = "true"
    "REDIS_CLUSTER_NAME" = module.redis_enterprise.cluster_name
    "REDIS_USE_ENTRA_ID" = "true"

    # Azure Configuration for Redis Management API
    "AZURE_SUBSCRIPTION_ID" = data.azurerm_client_config.current.subscription_id
    "AZURE_RESOURCE_GROUP"  = data.azurerm_resource_group.main.name

    # Application Configuration
    "FLASK_ENV"                      = "production"
    "PYTHONUNBUFFERED"               = "1"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"

    # API Configuration
    "API_KEY" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.api_key.id})"

    # Application Insights
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.redis_test.connection_string

    # Azure Identity Configuration (for managed identity)
    "AZURE_CLIENT_ID" = azurerm_user_assigned_identity.redis.client_id
  }

  # Enable HTTPS only
  https_only = true

  # Managed Identity for Key Vault access
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.redis.id
    ]
  }

  # Key Vault reference configuration
  key_vault_reference_identity_id = azurerm_user_assigned_identity.redis.id

  logs {
    application_logs {
      file_system_level = "Information"
    }

    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }

  tags = merge(var.tags, {
    "Purpose" = "Redis Testing Application"
  })

  depends_on = [
    module.redis_enterprise,
    azurerm_role_assignment.kv_secrets_user
  ]
}

# Application Insights for monitoring
resource "azurerm_application_insights" "redis_test" {
  name                = "appi-${var.redis_name}-test"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.redis.id

  tags = merge(var.tags, {
    "Purpose" = "Redis Testing Application Monitoring"
  })
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "redis" {
  name                = "log-${var.redis_name}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

# Store Redis password in Key Vault for App Service
resource "azurerm_key_vault_secret" "redis_password" {
  name         = "redis-password"
  value        = "placeholder" # Will be updated after Redis deployment
  key_vault_id = azurerm_key_vault.redis.id

  depends_on = [
    azurerm_role_assignment.current_user_kv_admin
  ]

  lifecycle {
    ignore_changes = [value] # Password will be updated manually or via script
  }
}

# Generate API key for testing app
resource "random_password" "api_key" {
  length  = 32
  special = true
}

# Store API key in Key Vault
resource "azurerm_key_vault_secret" "api_key" {
  name         = "api-key"
  value        = random_password.api_key.result
  key_vault_id = azurerm_key_vault.redis.id

  depends_on = [
    azurerm_role_assignment.current_user_kv_admin
  ]
}

# Role assignment for App Service to read Key Vault secrets
resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.redis.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.redis.principal_id
}

# Automated App Deployment using Azure CLI
resource "null_resource" "deploy_app" {
  # Trigger redeployment if app.zip changes or app service is recreated
  triggers = {
    app_zip_hash    = filemd5("${path.module}/app.zip")
    app_service_id  = azurerm_linux_web_app.redis_test.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "🚀 Deploying application code to ${azurerm_linux_web_app.redis_test.name}..."
      
      # Wait for App Service to be fully ready
      sleep 30
      
      # Deploy the app.zip using Azure CLI
      az webapp deployment source config-zip \
        --resource-group ${data.azurerm_resource_group.main.name} \
        --name ${azurerm_linux_web_app.redis_test.name} \
        --src ${path.module}/app.zip
      
      echo "✅ Application deployment complete!"
      
      # Wait for deployment to complete and app to start
      sleep 45
      
      echo "🔍 Checking app health..."
      APP_URL="https://${azurerm_linux_web_app.redis_test.default_hostname}"
      
      # Try to reach health endpoint (may take a few minutes for first start)
      for i in {1..10}; do
        if curl -sf "$APP_URL/api/health" > /dev/null 2>&1; then
          echo "✅ App is healthy and responding!"
          break
        else
          echo "⏳ Waiting for app to start (attempt $i/10)..."
          sleep 15
        fi
      done
    EOT
  }

  depends_on = [
    azurerm_linux_web_app.redis_test,
    azurerm_role_assignment.kv_secrets_user,
    azurerm_role_assignment.redis_contributor,
    module.redis_enterprise
  ]
}
