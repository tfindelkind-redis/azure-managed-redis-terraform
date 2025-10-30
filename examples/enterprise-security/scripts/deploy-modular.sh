#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Modular Azure Redis Deployment${NC}"
echo -e "${BLUE}===================================${NC}"
echo ""

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo -e "${RED}❌ Error: terraform.tfvars not found${NC}"
    echo "Please create terraform.tfvars first"
    exit 1
fi

# Initialize if needed
if [ ! -d ".terraform" ]; then
    echo -e "${BLUE}📦 Initializing Terraform...${NC}"
    terraform init
    echo ""
fi

# Function to deploy specific resources
deploy_module() {
    local module_name=$1
    local resources=$2
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📦 Module: ${module_name}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    echo -e "${YELLOW}Resources to deploy:${NC}"
    echo "$resources" | sed 's/^/  - /'
    echo ""
    
    read -p "Deploy this module? (y/n/skip): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}✅ Deploying ${module_name}...${NC}"
        
        # Build terraform command with multiple -target flags
        local targets=""
        while IFS= read -r resource; do
            if [ -n "$resource" ]; then
                targets="$targets -target=\"$resource\""
            fi
        done <<< "$resources"
        
        # Execute terraform apply with all targets
        eval "terraform apply $targets -auto-approve"
        
        echo ""
        echo -e "${GREEN}✅ ${module_name} deployed successfully${NC}"
        return 0
    elif [[ $REPLY =~ ^[Ss]$ ]]; then
        echo -e "${YELLOW}⏭️  Skipping ${module_name}${NC}"
        return 0
    else
        echo -e "${RED}❌ Deployment cancelled${NC}"
        return 1
    fi
    echo ""
}

# Function to show deployment plan
show_plan() {
    echo -e "${BLUE}📋 Deployment Plan${NC}"
    echo -e "${BLUE}==================${NC}"
    echo ""
    echo "This script will deploy resources in phases:"
    echo ""
    echo "  Phase 0: Random Suffix"
    echo "    • Generate unique suffix for resource names"
    echo ""
    echo "  Phase 1: Foundation"
    echo "    • Resource Group (data source)"
    echo "    • Network (VNet + Subnet)"
    echo ""
    echo "  Phase 2: Security Identity"
    echo "    • User-Assigned Managed Identity (Redis)"
    echo "    • User-Assigned Managed Identity (Key Vault)"
    echo ""
    echo "  Phase 3: Key Vault & Encryption"
    echo "    • Key Vault (Premium SKU)"
    echo "    • Customer Managed Key (RSA 2048)"
    echo "    • Access Policies & Role Assignments"
    echo "    • RBAC Propagation Wait (60s)"
    echo ""
    echo "  Phase 4: Redis Cache + Private Link"
    echo "    • Redis Enterprise Cluster"
    echo "    • Database with Modules"
    echo "    • Private Endpoint (automatically included)"
    echo "    • Private DNS Zone (automatically included)"
    echo "    • DNS Zone Virtual Network Link (automatically included)"
    echo ""
    echo "  Phase 5: Testing App Service (Optional)"
    echo "    • App Service Plan (S1)"
    echo "    • App Service (Web App)"
    echo "    • Application Insights"
    echo "    • Log Analytics Workspace"
    echo "    • Flask Testing Application"
    echo ""
    echo -e "${YELLOW}💡 Tip: You can skip phases and deploy only what you need!${NC}"
    echo -e "${YELLOW}💡 Note: Private Link is now automatically included with Redis (Phase 4)${NC}"
    echo ""
}

# Show the plan
show_plan

read -p "Continue with modular deployment? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Deployment cancelled${NC}"
    exit 0
fi
echo ""

# Phase 0: Random Suffix (if needed)
if ! deploy_module "Phase 0: Generate Random Suffix" \
"random_integer.suffix"; then
    exit 1
fi

# Phase 1: Foundation (Network)
if ! deploy_module "Phase 1: Foundation - Network" \
"azurerm_virtual_network.redis
azurerm_subnet.redis"; then
    exit 1
fi

# Phase 2: Security Identity
if ! deploy_module "Phase 2: Security - Managed Identities" \
"azurerm_user_assigned_identity.redis
azurerm_user_assigned_identity.keyvault"; then
    exit 1
fi

# Phase 3: Key Vault & Encryption
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📦 Phase 3: Key Vault & Encryption${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Resources to deploy:${NC}"
echo "  - Key Vault (Premium SKU with purge protection)"
echo "  - Customer Managed Key (RSA 2048)"
echo "  - Role Assignment (Crypto Service Encryption User)"
echo ""

read -p "Deploy Key Vault module? (y/n/skip): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}✅ Deploying Key Vault...${NC}"
    
    # Deploy Key Vault first
    terraform apply \
        -target="azurerm_key_vault.redis" \
        -auto-approve
    
    # Deploy Key Vault Key
    terraform apply \
        -target="azurerm_key_vault_key.redis" \
        -auto-approve
    
    # Deploy Role Assignments
    terraform apply \
        -target="azurerm_role_assignment.current_user_kv_admin" \
        -target="azurerm_role_assignment.kv_crypto_user" \
        -auto-approve
    
    # Wait for RBAC to propagate
    terraform apply \
        -target="time_sleep.wait_for_rbac" \
        -auto-approve
    
    echo ""
    echo -e "${GREEN}✅ Key Vault deployed successfully${NC}"
elif [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}⏭️  Skipping Key Vault${NC}"
else
    echo -e "${RED}❌ Deployment cancelled${NC}"
    exit 1
fi
echo ""

# Phase 4: Redis Cache with Private Link
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📦 Phase 4: Redis Enterprise Cache + Private Link${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Resources to deploy:${NC}"
echo "  - Redis Enterprise Cluster (Balanced_B3)"
echo "  - Customer Managed Key Encryption"
echo "  - User-Assigned Managed Identity"
echo "  - Redis Modules (JSON, Search)"
echo "  - Private Endpoint (no public access)"
echo "  - Private DNS Zone"
echo "  - DNS Zone Virtual Network Link"
echo ""
echo -e "${RED}⚠️  Note: This is the most expensive resource (~\$400/month)${NC}"
echo -e "${YELLOW}💡 Private Link is included for enterprise security${NC}"
echo ""

read -p "Deploy Redis Cache with Private Link? (y/n/skip): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}✅ Deploying Redis Cache...${NC}"
    echo -e "${YELLOW}⏱️  This may take 15-20 minutes...${NC}"
    
    # Deploy Redis first
    terraform apply \
        -target="azurerm_managed_redis.main" \
        -auto-approve
    
    echo ""
    echo -e "${GREEN}✅ Redis Cache deployed successfully${NC}"
    echo ""
    
    # Automatically deploy Private Link (no separate prompt)
    echo -e "${GREEN}✅ Deploying Private Link...${NC}"
    
    # Deploy Private DNS Zone first
    terraform apply \
        -target="azurerm_private_dns_zone.redis" \
        -auto-approve
    
    # Deploy Private Endpoint
    terraform apply \
        -target="azurerm_private_endpoint.redis" \
        -auto-approve
    
    # Link DNS Zone to VNet
    terraform apply \
        -target="azurerm_private_dns_zone_virtual_network_link.redis" \
        -auto-approve
    
    echo ""
    echo -e "${GREEN}✅ Private Link deployed successfully${NC}"
    echo -e "${GREEN}🔒 Redis is now accessible only via private endpoint${NC}"
    
elif [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}⏭️  Skipping Redis Cache and Private Link${NC}"
else
    echo -e "${RED}❌ Deployment cancelled${NC}"
    exit 1
fi
echo ""

# Phase 5: Testing App Service (Optional)
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📦 Phase 5: Testing App Service (Optional)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Resources to deploy:${NC}"
echo "  - App Service Plan (S1 - Linux)"
echo "  - App Service (Python 3.11)"
echo "  - Application Insights"
echo "  - Log Analytics Workspace"
echo "  - VNet Integration for Private Link access"
echo ""
echo -e "${YELLOW}💡 Cost: ~\$70/month for App Service S1${NC}"
echo ""

read -p "Deploy Testing App Service? (y/n/skip): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}✅ Deploying Testing App Service...${NC}"
    
    # Generate API key
    terraform apply \
        -target="random_password.api_key" \
        -auto-approve
    
    # Deploy Log Analytics Workspace first
    terraform apply \
        -target="azurerm_log_analytics_workspace.redis" \
        -auto-approve
    
    # Deploy Application Insights
    terraform apply \
        -target="azurerm_application_insights.redis_test" \
        -auto-approve
    
    # Deploy Key Vault secrets (API key and Redis password placeholder)
    terraform apply \
        -target="azurerm_key_vault_secret.api_key" \
        -target="azurerm_key_vault_secret.redis_password" \
        -auto-approve
    
    # Deploy role assignment for Key Vault access
    terraform apply \
        -target="azurerm_role_assignment.kv_secrets_user" \
        -auto-approve
    
    # Deploy App Service Plan
    terraform apply \
        -target="azurerm_service_plan.redis_test" \
        -auto-approve
    
    # Deploy App Service
    terraform apply \
        -target="azurerm_linux_web_app.redis_test" \
        -auto-approve
    
    echo ""
    echo -e "${GREEN}✅ Testing App Service deployed successfully${NC}"
    echo ""
    
    # Ask if user wants to deploy the Flask app
    echo -e "${YELLOW}Would you like to deploy the Flask testing application now?${NC}"
    read -p "Deploy Flask app? (y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Deploying Flask application...${NC}"
        
        # Change to app directory
        cd testing-app
        
        # Create clean deployment package
        ZIP_FILE="../redis-test-app.zip"
        rm -f "$ZIP_FILE"
        
        echo -e "${YELLOW}Creating clean deployment package...${NC}"
        zip -r "$ZIP_FILE" . \
            -x "*.pyc" \
            -x "**/__pycache__/*" \
            -x "__pycache__/*" \
            -x ".pytest_cache/*" \
            -x "*.egg-info/*" \
            -x ".env*" \
            -x ".git/*" \
            -x "*.log" \
            -x ".DS_Store" \
            -x "venv/*" \
            -x ".venv/*" \
            -x "test-venv/*" \
            -x "env/*" \
            -x ".env/*" \
            > /dev/null 2>&1
        
        # Verify package size
        PKG_SIZE=$(ls -lh "$ZIP_FILE" | awk '{print $5}')
        echo -e "${GREEN}✓ Clean package created: $PKG_SIZE${NC}"
        
        # Go back to terraform directory
        cd ..
        
        # Get App Service details
        APP_NAME=$(terraform output -raw app_service_name)
        RESOURCE_GROUP=$(terraform output -raw resource_group_name)
        
        echo -e "${YELLOW}Deploying to App Service: ${APP_NAME}...${NC}"
        echo -e "${YELLOW}This may take a few minutes...${NC}"
        
        # Use az webapp deploy (newer method)
        if az webapp deploy \
            --resource-group "$RESOURCE_GROUP" \
            --name "$APP_NAME" \
            --src-path "$ZIP_FILE" \
            --type zip \
            --clean true \
            --restart true \
            --async false 2>&1 | tee /tmp/deploy.log; then
            echo -e "${GREEN}✓ App deployment successful${NC}"
        else
            echo -e "${RED}⚠️  App deployment may have failed${NC}"
            echo -e "${YELLOW}   Check logs: https://${APP_NAME}.scm.azurewebsites.net${NC}"
            echo -e "${YELLOW}   If Azure is experiencing issues, try again later${NC}"
        fi
        
        # Note: Redis is using Entra ID authentication (access keys disabled)
        # No password needed - the App Service uses managed identity
        echo -e "${YELLOW}ℹ️  Redis is configured with Entra ID authentication${NC}"
        echo -e "${YELLOW}   App Service will authenticate using managed identity${NC}"
        
        # Restart App Service
        echo -e "${YELLOW}Restarting App Service...${NC}"
        az webapp restart \
            --resource-group "$RESOURCE_GROUP" \
            --name "$APP_NAME" \
            --output none 2>/dev/null
        
        # Clean up
        rm -f "$ZIP_FILE"
        
        echo ""
        echo -e "${GREEN}✅ Flask application deployed successfully${NC}"
        echo ""
        
        # Show App Service URL
        APP_URL=$(terraform output -raw app_service_url)
        echo -e "${BLUE}🌐 Application URL:${NC}"
        echo -e "  ${GREEN}${APP_URL}${NC}"
        echo ""
    else
        echo -e "${YELLOW}ℹ️  Skipping Flask app deployment${NC}"
        echo -e "${YELLOW}   You can deploy it later with: ./deploy-test-app.sh${NC}"
    fi
    
elif [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}⏭️  Skipping Testing App Service${NC}"
else
    echo -e "${RED}❌ Deployment cancelled${NC}"
    exit 1
fi
echo ""

# Final Summary
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Modular Deployment Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Show what was deployed
echo -e "${BLUE}📊 Deployed Resources:${NC}"
terraform state list
echo ""

# Show outputs
echo -e "${BLUE}📋 Connection Information:${NC}"
terraform output
echo ""

echo -e "${BLUE}🧪 Next Steps:${NC}"
echo ""

# Check if App Service was deployed
APP_SERVICE_DEPLOYED=$(terraform state list 2>/dev/null | grep -c "azurerm_linux_web_app.redis_test" || echo "0")

if [ "$APP_SERVICE_DEPLOYED" -gt 0 ]; then
    APP_URL=$(terraform output -raw app_service_url 2>/dev/null || echo "")
    if [ -n "$APP_URL" ]; then
        echo "  ${GREEN}1. Access Testing Dashboard:${NC}"
        echo "     ${BLUE}${APP_URL}${NC}"
        echo ""
        echo "  ${GREEN}2. Get API Key:${NC}"
        echo "     ${YELLOW}$(terraform output -raw api_key_command 2>/dev/null)${NC}"
        echo ""
        echo "  ${GREEN}3. Test Redis Connection (via Entra ID):${NC}"
        echo "     ${YELLOW}curl ${APP_URL}/health${NC}"
        echo ""
        echo "  ${GREEN}4. Test Redis Operations:${NC}"
        echo "     ${YELLOW}curl -X POST ${APP_URL}/api/redis/test \\${NC}"
        echo "     ${YELLOW}  -H \"X-API-Key: \$(az keyvault secret show --vault-name <vault> --name api-key --query value -o tsv)\"${NC}"
        echo ""
        echo "  ${GREEN}5. Verify Entra ID Authentication:${NC}"
        echo "     ${YELLOW}Check App Service logs for \"Using Entra ID managed identity authentication\"${NC}"
        echo ""
    fi
else
    echo "  ${GREEN}1. Deploy Testing App Service:${NC}"
    echo "     ${YELLOW}./deploy-modular.sh${NC} (and select Yes for Phase 6)"
    echo "     OR"
    echo "     ${YELLOW}terraform apply -target=azurerm_linux_web_app.redis_test${NC}"
    echo ""
fi

echo "  ${GREEN}View deployment details:${NC}"
echo "     ${YELLOW}terraform show${NC}"
echo ""
echo "  ${GREEN}If something failed, re-run this script:${NC}"
echo "     ${YELLOW}./deploy-modular.sh${NC}"
echo "     (Already deployed resources will be skipped)"
echo ""

echo -e "${YELLOW}💡 Pro Tips:${NC}"
echo "  • To redeploy only Redis: terraform apply -target=azurerm_managed_redis.main"
echo "  • To redeploy only Key Vault: terraform apply -target=azurerm_key_vault.redis"
echo "  • To redeploy only Private Endpoint: terraform apply -target=azurerm_private_endpoint.redis"
echo "  • To redeploy only App Service: terraform apply -target=azurerm_linux_web_app.redis_test"
echo "  • To see the full plan: terraform plan"
echo ""
