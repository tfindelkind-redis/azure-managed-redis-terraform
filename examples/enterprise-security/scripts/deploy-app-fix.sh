#!/bin/bash
set -e

##############################################################################
# Quick Deploy Flask App Fix
# Use this to quickly deploy application code changes without redeploying
# the entire infrastructure
##############################################################################

echo "🚀 Quick Deploy Flask App Fix"
echo "==============================="
echo ""

# Check if we're in the right directory
if [ ! -f "terraform.tfvars" ]; then
    echo "❌ Error: Must run from enterprise-security directory"
    exit 1
fi

# Get Terraform outputs
echo "📊 Getting deployment information..."
APP_NAME=$(terraform output -raw app_service_name 2>/dev/null)
RG_NAME=$(terraform output -raw resource_group_name 2>/dev/null)

if [ -z "$APP_NAME" ] || [ -z "$RG_NAME" ]; then
    echo "❌ Error: Could not get Terraform outputs"
    echo "   Make sure the infrastructure is deployed first"
    exit 1
fi

echo "📦 App Service: $APP_NAME"
echo "📁 Resource Group: $RG_NAME"
echo ""

# Syntax check
echo "🔍 Running syntax check..."
if [ -f "scripts/check-app-syntax.sh" ]; then
    ./scripts/check-app-syntax.sh
else
    echo "⚠️  Syntax check script not found, skipping..."
fi
echo ""

# Create package
echo "📦 Creating deployment package..."
cd testing-app
ZIP_FILE="../app-fix.zip"
rm -f "$ZIP_FILE"

zip -r "$ZIP_FILE" . \
    -x "*.pyc" \
    -x "__pycache__/*" \
    -x ".env*" \
    -x ".git/*" \
    -x "*.log" \
    -x ".DS_Store" \
    -x "venv/*" \
    -x ".venv/*" \
    > /dev/null 2>&1

cd ..
echo "✓ Package created: $(du -h app-fix.zip | cut -f1)"
echo ""

# Deploy
echo "🚀 Deploying to Azure App Service..."
az webapp deployment source config-zip \
    --resource-group "$RG_NAME" \
    --name "$APP_NAME" \
    --src app-fix.zip \
    --timeout 600 \
    > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✓ Deployed successfully"
else
    echo "❌ Deployment failed"
    rm app-fix.zip
    exit 1
fi
echo ""

# Restart
echo "🔄 Restarting app..."
az webapp restart \
    --resource-group "$RG_NAME" \
    --name "$APP_NAME" \
    --output none

if [ $? -eq 0 ]; then
    echo "✓ Restarted successfully"
else
    echo "❌ Restart failed"
fi
echo ""

# Clean up
rm app-fix.zip

# Get URL
APP_URL=$(terraform output -raw app_service_url 2>/dev/null)

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✅ Deployment Complete!                                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "🌐 App URL: $APP_URL"
echo ""
echo "Next steps:"
echo "  1. Visit: $APP_URL"
echo "  2. Test your changes"
echo "  3. Check logs if needed:"
echo "     az webapp log tail --resource-group $RG_NAME --name $APP_NAME"
echo ""
