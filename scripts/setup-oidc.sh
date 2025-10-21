#!/bin/bash

# Azure Managed Redis - OIDC Setup Script
# This script sets up Azure Workload Identity (OIDC) for GitHub Actions
# and automatically configures GitHub repository secrets using GitHub CLI
#
# Usage:
#   ./setup-oidc.sh           # Run the setup
#   ./setup-oidc.sh --dry-run # Show what would be done without making changes

set -e

# Check for flags
DRY_RUN=false
SHOW_HELP=false

for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            ;;
        --help|-h)
            SHOW_HELP=true
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

if [[ "$SHOW_HELP" == "true" ]]; then
    echo "Azure Managed Redis - OIDC Setup Script"
    echo "========================================"
    echo ""
    echo "This script sets up Azure Workload Identity (OIDC) for GitHub Actions"
    echo "and automatically configures GitHub repository secrets using GitHub CLI."
    echo ""
    echo "Prerequisites:"
    echo "  • Azure CLI installed and authenticated"
    echo "  • GitHub CLI installed and authenticated"
    echo "  • Appropriate Azure AD permissions"
    echo ""
    echo "Usage:"
    echo "  $0              # Run the setup interactively"
    echo "  $0 --dry-run    # Show what would be done without making changes"
    echo "  $0 --help       # Show this help message"
    echo ""
    echo "What this script does:"
    echo "  1. Creates Azure AD Application"
    echo "  2. Creates Service Principal"
    echo "  3. Creates/verifies resource group"
    echo "  4. Assigns Contributor role to resource group"
    echo "  5. Creates federated credentials for GitHub OIDC"
    echo "  6. Sets GitHub repository secrets automatically"
    echo ""
    exit 0
fi

if [[ "$DRY_RUN" == "true" ]]; then
    echo "🔍 DRY RUN MODE - No changes will be made"
fi

echo "🔐 Setting up Azure Workload Identity (OIDC) for GitHub Actions"
echo "================================================================"

# Check if GitHub CLI is installed and authenticated
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed. Please install it first:"
    echo "   https://cli.github.com/"
    exit 1
fi

# Check if GitHub CLI is authenticated
if ! gh auth status &> /dev/null; then
    echo "🔑 GitHub CLI is not authenticated. Please authenticate first:"
    echo "   gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is installed and authenticated"

# Get user input
read -p "Enter your GitHub username/organization: " REPO_OWNER
read -p "Enter your repository name [azure-managed-redis-terraform]: " REPO_NAME
REPO_NAME=${REPO_NAME:-azure-managed-redis-terraform}
read -p "Enter your target resource group name [rg-azure-managed-redis-terraform]: " RESOURCE_GROUP
RESOURCE_GROUP=${RESOURCE_GROUP:-rg-azure-managed-redis-terraform}

# Verify the repository exists and we have access
REPO_FULL_NAME="${REPO_OWNER}/${REPO_NAME}"
if ! gh repo view "$REPO_FULL_NAME" &> /dev/null; then
    echo "❌ Cannot access repository: $REPO_FULL_NAME"
    echo "   Please check the repository name and your GitHub permissions"
    exit 1
fi

echo "✅ Repository access confirmed: $REPO_FULL_NAME"

# Get Azure details
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
APP_NAME="github-${REPO_NAME}-oidc"

echo ""
echo "📋 Configuration Summary:"
echo "  Repository: ${REPO_OWNER}/${REPO_NAME}"
echo "  Resource Group: ${RESOURCE_GROUP}"
echo "  Subscription: ${SUBSCRIPTION_ID}"
echo "  Tenant: ${TENANT_ID}"
echo "  App Name: ${APP_NAME}"
if [[ "$DRY_RUN" == "true" ]]; then
    echo "  🔍 Mode: DRY RUN (no changes will be made)"
fi
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    echo "🔍 DRY RUN: This is what would be done:"
    echo "  1. Create Azure AD Application: $APP_NAME"
    echo "  2. Create Service Principal for application"
    echo "  3. Create/verify resource group: $RESOURCE_GROUP"
    echo "  4. Assign Contributor role to resource group"
    echo "  5. Create federated credential for main branch"
    echo "  6. Create federated credential for pull requests"
    echo "  7. Set GitHub repository secrets using gh CLI"
    echo ""
    echo "To actually run the setup, execute without --dry-run flag"
    exit 0
fi

read -p "Continue with this configuration? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "❌ Setup cancelled"
    exit 1
fi

echo ""
echo "🚀 Starting setup..."

# Step 1: Create Azure AD Application
echo "1️⃣ Creating Azure AD Application..."
az ad app create --display-name "$APP_NAME" --query '{appId: appId, displayName: displayName}' --output table

# Get the Application ID
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)
echo "   ✅ Created application with ID: $APP_ID"

# Step 2: Create Service Principal
echo "2️⃣ Creating Service Principal..."
az ad sp create --id $APP_ID --query '{appId: appId, displayName: displayName}' --output table 2>/dev/null || echo "   ℹ️ Service principal already exists"

# Step 3: Create resource group (if it doesn't exist)
echo "3️⃣ Ensuring resource group exists..."
az group create --name $RESOURCE_GROUP --location "North Europe" --output table || echo "   ℹ️ Resource group already exists"

# Step 4: Assign Contributor role to the resource group
echo "4️⃣ Assigning Contributor role to resource group..."
az role assignment create \
  --assignee $APP_ID \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" \
  --output table || echo "   ℹ️ Role assignment already exists"

# Step 5: Create federated credential for main branch
echo "5️⃣ Creating federated credential for main branch..."
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$REPO_OWNER'/'$REPO_NAME':ref:refs/heads/main",
    "description": "GitHub Actions - Main Branch",
    "audiences": ["api://AzureADTokenExchange"]
  }' --output table || echo "   ℹ️ Federated credential for main branch already exists"

# Step 6: Create federated credential for pull requests
echo "6️⃣ Creating federated credential for pull requests..."
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-actions-pr",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$REPO_OWNER'/'$REPO_NAME':pull_request",
    "description": "GitHub Actions - Pull Requests",
    "audiences": ["api://AzureADTokenExchange"]
  }' --output table || echo "   ℹ️ Federated credential for pull requests already exists"

# Step 7: Set GitHub repository secrets using GitHub CLI
echo "7️⃣ Setting GitHub repository secrets..."

echo "   Setting AZURE_CLIENT_ID..."
echo "$APP_ID" | gh secret set AZURE_CLIENT_ID --repo "$REPO_FULL_NAME"

echo "   Setting AZURE_TENANT_ID..."
echo "$TENANT_ID" | gh secret set AZURE_TENANT_ID --repo "$REPO_FULL_NAME"

echo "   Setting AZURE_SUBSCRIPTION_ID..."
echo "$SUBSCRIPTION_ID" | gh secret set AZURE_SUBSCRIPTION_ID --repo "$REPO_FULL_NAME"

echo "   Setting AZURE_RESOURCE_GROUP..."
echo "$RESOURCE_GROUP" | gh secret set AZURE_RESOURCE_GROUP --repo "$REPO_FULL_NAME"

echo "   ✅ All GitHub secrets have been set automatically!"

echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo ""
echo "✅ Configuration Summary:"
echo "   🔐 Azure AD Application: $APP_NAME ($APP_ID)"
echo "   🏢 Resource Group: $RESOURCE_GROUP"
echo "   📦 Subscription: $SUBSCRIPTION_ID"
echo "   🎯 Repository: $REPO_FULL_NAME"
echo ""
echo "🔑 GitHub Secrets Configured:"
echo "   ✅ AZURE_CLIENT_ID"
echo "   ✅ AZURE_TENANT_ID"  
echo "   ✅ AZURE_SUBSCRIPTION_ID"
echo "   ✅ AZURE_RESOURCE_GROUP"
echo ""
echo "🔐 Security Features Enabled:"
echo "   • ✅ No client secret needed - OIDC handles authentication!"
echo "   • ✅ Short-lived tokens only (automatically expire)"
echo "   • ✅ Repository-specific access (only your repo can use this identity)"
echo "   • ✅ Resource group scoped permissions (limited blast radius)"
echo "   • ✅ Branch-specific federated credentials (main + PRs)"
echo ""
echo "🚀 Your GitHub Actions workflows are now ready!"
echo "   Run a workflow to test the OIDC authentication."
