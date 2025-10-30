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
cd testing-app

# Create deployment package
echo -e "${YELLOW}Creating clean deployment package...${NC}"
ZIP_FILE="../redis-test-app.zip"

# Remove old zip if exists
rm -f "$ZIP_FILE"

# Create zip excluding ALL virtual environments and cache files
# This ensures a clean build every time
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

# Verify the package size (should be small, ~15-20KB)
PKG_SIZE=$(ls -lh "$ZIP_FILE" | awk '{print $5}')
echo -e "${GREEN}✓ Clean deployment package created: $ZIP_FILE ($PKG_SIZE)${NC}"

# Warn if package is too large (might contain venv)
if [ -f "$ZIP_FILE" ]; then
    SIZE_BYTES=$(stat -f%z "$ZIP_FILE" 2>/dev/null || stat -c%s "$ZIP_FILE" 2>/dev/null)
    if [ "$SIZE_BYTES" -gt 100000 ]; then
        echo -e "${YELLOW}⚠️  Warning: Package size is ${PKG_SIZE}, which seems large${NC}"
        echo -e "${YELLOW}   Make sure virtual environments are excluded${NC}"
    fi
fi
echo ""

# Deploy to App Service
echo -e "${YELLOW}Deploying to Azure App Service...${NC}"
echo -e "${BLUE}This may take a few minutes...${NC}"
echo ""

# Use the newer az webapp deploy command instead of deprecated config-zip
az webapp deploy \
    --resource-group "$RESOURCE_GROUP" \
    --name "$APP_NAME" \
    --src-path "$ZIP_FILE" \
    --type zip \
    --clean true \
    --restart true \
    --async false

echo ""
echo -e "${GREEN}✓ Deployment completed successfully!${NC}"
echo ""

# Note: Redis is using Entra ID authentication (access keys disabled)
# No password needed - the App Service uses managed identity
echo -e "${YELLOW}ℹ️  Redis is configured with Entra ID authentication${NC}"
echo -e "${YELLOW}   App Service will authenticate using managed identity${NC}"
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
