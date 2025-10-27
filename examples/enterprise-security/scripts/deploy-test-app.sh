#!/bin/bash

##############################################################################
# Deploy Redis Testing App to Azure App Service
#
# This script deploys the Flask application to Azure App Service
# Prerequisites: Terraform infrastructure must be deployed first
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Redis Testing App Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Change to script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Get App Service name from Terraform
echo -e "${YELLOW}Getting deployment configuration from Terraform...${NC}"
cd ..
APP_NAME=$(terraform output -raw app_service_name 2>/dev/null)
RESOURCE_GROUP=$(terraform output -raw resource_group_name 2>/dev/null)

if [ -z "$APP_NAME" ] || [ -z "$RESOURCE_GROUP" ]; then
    echo -e "${RED}❌ Failed to get App Service details from Terraform${NC}"
    echo -e "${YELLOW}Please ensure Terraform infrastructure is deployed first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ App Service: $APP_NAME${NC}"
echo -e "${GREEN}✓ Resource Group: $RESOURCE_GROUP${NC}"
echo ""

# Go back to app directory
cd redis-test-app

# Create deployment package
echo -e "${YELLOW}Creating deployment package...${NC}"
ZIP_FILE="../redis-test-app.zip"

# Remove old zip if exists
rm -f "$ZIP_FILE"

# Create zip (exclude unnecessary files)
zip -r "$ZIP_FILE" . \
    -x "*.pyc" \
    -x "__pycache__/*" \
    -x ".env" \
    -x ".git/*" \
    -x "*.log" \
    -x ".DS_Store" \
    -x "venv/*" \
    -x ".venv/*" \
    > /dev/null

echo -e "${GREEN}✓ Deployment package created: $ZIP_FILE${NC}"
echo ""

# Deploy to App Service
echo -e "${YELLOW}Deploying to Azure App Service...${NC}"
echo -e "${BLUE}This may take a few minutes...${NC}"
echo ""

az webapp deployment source config-zip \
    --resource-group "$RESOURCE_GROUP" \
    --name "$APP_NAME" \
    --src "$ZIP_FILE" \
    --timeout 600

echo ""
echo -e "${GREEN}✓ Deployment completed successfully!${NC}"
echo ""

# Update Redis password in Key Vault (if Redis is deployed)
echo -e "${YELLOW}Checking if Redis is deployed...${NC}"
REDIS_NAME=$(cd .. && terraform output -raw cluster_name 2>/dev/null)

if [ -n "$REDIS_NAME" ]; then
    echo -e "${GREEN}✓ Redis found: $REDIS_NAME${NC}"
    echo -e "${YELLOW}Updating Redis password in Key Vault...${NC}"
    
    # Get Redis password
    REDIS_PASSWORD=$(az redisenterprise database list-keys \
        --cluster-name "$REDIS_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query primaryKey -o tsv 2>/dev/null)
    
    if [ -n "$REDIS_PASSWORD" ]; then
        # Get Key Vault name
        KEY_VAULT_NAME=$(cd .. && terraform output -json key_vault_id | jq -r 'split("/") | .[-1]')
        
        # Update secret
        az keyvault secret set \
            --vault-name "$KEY_VAULT_NAME" \
            --name "redis-password" \
            --value "$REDIS_PASSWORD" \
            --output none
        
        echo -e "${GREEN}✓ Redis password updated in Key Vault${NC}"
    else
        echo -e "${YELLOW}⚠️  Could not retrieve Redis password${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Redis not deployed yet - password will need to be updated manually${NC}"
fi

echo ""

# Restart App Service to pick up new settings
echo -e "${YELLOW}Restarting App Service...${NC}"
az webapp restart \
    --resource-group "$RESOURCE_GROUP" \
    --name "$APP_NAME" \
    --output none

echo -e "${GREEN}✓ App Service restarted${NC}"
echo ""

# Get App Service URL
APP_URL=$(cd .. && terraform output -raw app_service_url)

# Get API key command
API_KEY_CMD=$(cd .. && terraform output -raw api_key_command)

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Application URL:${NC}"
echo -e "  ${GREEN}$APP_URL${NC}"
echo ""
echo -e "${BLUE}To get the API key, run:${NC}"
echo -e "  ${YELLOW}$API_KEY_CMD${NC}"
echo ""
echo -e "${BLUE}Test the API:${NC}"
echo -e "  ${YELLOW}curl -X POST $APP_URL/api/redis/test \\${NC}"
echo -e "  ${YELLOW}  -H \"X-API-Key: \$(az keyvault secret show --vault-name <vault> --name api-key --query value -o tsv)\"${NC}"
echo ""
echo -e "${BLUE}View logs:${NC}"
echo -e "  ${YELLOW}az webapp log tail --resource-group $RESOURCE_GROUP --name $APP_NAME${NC}"
echo ""

# Clean up
rm -f "$ZIP_FILE"
