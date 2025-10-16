# 🚀 Complete Setup Guide

This guide walks you through setting up GitHub Codespaces, creating Azure Service Principals, and configuring GitHub Secrets for automated CI/CD workflows.

## 📋 Table of Contents

1. [GitHub Codespaces Setup](#github-codespaces-setup)
2. [Azure Authentication Setup](#azure-authentication-setup)
3. [GitHub Secrets Configuration](#github-secrets-configuration)
4. [CI/CD Workflow Authentication](#cicd-workflow-authentication)
5. [Troubleshooting](#troubleshooting)

---

## 🌐 GitHub Codespaces Setup

### Quick Start (30 seconds)

1. **Open in Codespaces**:
   [![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/tfindelkind-redis/azure-managed-redis-terraform)

2. **Or create manually**:
   - Navigate to: `https://github.com/tfindelkind-redis/azure-managed-redis-terraform`
   - Click **"Code"** → **"Codespaces"** → **"Create codespace on main"**

3. **What you get automatically**:
   ```bash
   ✅ Pre-installed Tools:
   - Terraform (v1.6.0+)
   - Azure CLI (latest) 
   - GitHub CLI (auto-installed during setup)
   - redis-cli
   - Docker
   - tflint, tfsec, terraform-docs
   
   ✅ VS Code Extensions:
   - HashiCorp Terraform
   - Azure Account extensions
   - GitHub Copilot
   - YAML/JSON support
   
   ✅ Ready-to-use Examples:
   - All examples pre-configured
   - Validation scripts included
   - CI/CD workflows ready
   ```

### Codespace Environment Details

Your Codespace includes:

```bash
# Check installed tools (run these after Codespace starts)
terraform version    # Terraform v1.6.0+
az --version         # Azure CLI (latest)
gh --version         # GitHub CLI (installed during setup)
redis-cli --version  # redis-cli (installed during setup)
docker --version     # Docker (latest)
```

---

## 🔐 Azure Authentication Setup

### Step 1: Login to Azure in Codespace

```bash
# Login to Azure (opens browser authentication)
az login

# Verify login and list subscriptions
az account list --output table

# Set your preferred subscription (if you have multiple)
az account set --subscription "Your-Subscription-Name-or-ID"

# Verify current subscription
az account show --output table
```

### Step 2: Create Azure Service Principal

**Why do you need a Service Principal?**
- Enables automated authentication for CI/CD workflows
- Provides secure, non-interactive authentication for GitHub Actions
- Allows Terraform to authenticate with Azure without manual intervention

#### Option A: Quick Setup (Recommended)

```bash
# Create Service Principal with Contributor role for your subscription
az ad sp create-for-rbac \
  --name "terraform-redis-sp" \
  --role "Contributor" \
  --scopes "/subscriptions/$(az account show --query id -o tsv)" \
  --json-auth
```

**Example output**:
```json
{
  "clientId": "12345678-1234-1234-1234-123456789012",
  "clientSecret": "your-client-secret-here",
  "subscriptionId": "87654321-4321-4321-4321-210987654321",
  "tenantId": "11111111-1111-1111-1111-111111111111"
}
```

> **⚠️ Important**: Save this output! You'll need these values for GitHub Secrets.

#### Option B: Detailed Setup with Specific Permissions

```bash
# Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "Subscription ID: $SUBSCRIPTION_ID"

# Create the Service Principal
SP_OUTPUT=$(az ad sp create-for-rbac \
  --name "terraform-redis-sp" \
  --role "Contributor" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID")

# Extract values
CLIENT_ID=$(echo $SP_OUTPUT | jq -r '.appId')
CLIENT_SECRET=$(echo $SP_OUTPUT | jq -r '.password')  
TENANT_ID=$(echo $SP_OUTPUT | jq -r '.tenant')

# Display the values (save these!)
echo "=== Azure Service Principal Details ==="
echo "CLIENT_ID: $CLIENT_ID"
echo "CLIENT_SECRET: $CLIENT_SECRET"
echo "TENANT_ID: $TENANT_ID" 
echo "SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
```

#### Option C: Custom Resource Group Scope

If you want to limit permissions to a specific resource group:

```bash
# Create resource group first (if it doesn't exist)
RESOURCE_GROUP="rg-redis-terraform"
LOCATION="East US"

az group create --name $RESOURCE_GROUP --location "$LOCATION"

# Create Service Principal with resource group scope
az ad sp create-for-rbac \
  --name "terraform-redis-sp" \
  --role "Contributor" \
  --scopes "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP" \
  --json-auth
```

### Step 3: Verify Service Principal

```bash
# Test the Service Principal authentication
az login --service-principal \
  --username "$CLIENT_ID" \
  --password "$CLIENT_SECRET" \
  --tenant "$TENANT_ID"

# Verify it works
az account show

# Switch back to your user account
az login
```

---

## 🔑 GitHub Secrets Configuration

### Using GitHub CLI (Recommended in Codespace)

The GitHub CLI is pre-installed in your Codespace and provides the easiest way to manage secrets.

#### Step 1: Install GitHub CLI (if needed)

GitHub CLI should be auto-installed in your Codespace. If not, install it manually:

```bash
# Check if GitHub CLI is installed
if command -v gh &> /dev/null; then
    echo "✅ GitHub CLI is installed: $(gh --version)"
else
    echo "❌ GitHub CLI not found, installing..."
    # Install GitHub CLI
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update && sudo apt install -y gh
    echo "✅ GitHub CLI installed successfully"
fi
```

#### Step 2: Authenticate with GitHub

```bash
# Login to GitHub 
gh auth login

# Follow the prompts:
# 1. Select "GitHub.com"
# 2. Select "HTTPS" 
# 3. Select "Login with a web browser"
# 4. Copy the one-time code and open the browser
# 5. Paste the code and authorize

# Verify authentication
gh auth status
```

#### Step 3: Set Repository Secrets

Use the Service Principal details from the previous step:

```bash
# Set Azure authentication secrets
gh secret set AZURE_CLIENT_ID --body "YOUR_CLIENT_ID"
gh secret set AZURE_TENANT_ID --body "YOUR_TENANT_ID"  
gh secret set AZURE_SUBSCRIPTION_ID --body "YOUR_SUBSCRIPTION_ID"

# Set Terraform ARM provider secrets  
gh secret set ARM_CLIENT_ID --body "YOUR_CLIENT_ID"
gh secret set ARM_CLIENT_SECRET --body "YOUR_CLIENT_SECRET"
gh secret set ARM_TENANT_ID --body "YOUR_TENANT_ID"
gh secret set ARM_SUBSCRIPTION_ID --body "YOUR_SUBSCRIPTION_ID"
```

#### Step 4: Verify Secrets

```bash
# List all repository secrets
gh secret list

# Expected output:
# ARM_CLIENT_ID        Updated 2025-10-16T10:30:00Z
# ARM_CLIENT_SECRET    Updated 2025-10-16T10:30:00Z  
# ARM_SUBSCRIPTION_ID  Updated 2025-10-16T10:30:00Z
# ARM_TENANT_ID        Updated 2025-10-16T10:30:00Z
# AZURE_CLIENT_ID      Updated 2025-10-16T10:30:00Z
# AZURE_SUBSCRIPTION_ID Updated 2025-10-16T10:30:00Z
# AZURE_TENANT_ID      Updated 2025-10-16T10:30:00Z
```

### Alternative: Using GitHub Web Interface

If you prefer the web interface:

1. **Navigate to your repository** on GitHub.com
2. **Go to Settings** → **Secrets and variables** → **Actions**
3. **Click "New repository secret"** for each secret:

   | Secret Name | Description | Value Source |
   |-------------|-------------|--------------|
   | `AZURE_CLIENT_ID` | Azure Service Principal Client ID | `clientId` from Service Principal output |
   | `AZURE_TENANT_ID` | Azure AD Tenant ID | `tenantId` from Service Principal output |
   | `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID | `subscriptionId` from Service Principal output |
   | `ARM_CLIENT_ID` | Same as AZURE_CLIENT_ID | `clientId` from Service Principal output |
   | `ARM_CLIENT_SECRET` | Azure Service Principal Secret | `clientSecret` from Service Principal output |
   | `ARM_TENANT_ID` | Same as AZURE_TENANT_ID | `tenantId` from Service Principal output |
   | `ARM_SUBSCRIPTION_ID` | Same as AZURE_SUBSCRIPTION_ID | `subscriptionId` from Service Principal output |

---

## ⚙️ CI/CD Workflow Authentication

### Understanding the Workflows

This repository includes three main workflows:

1. **CI Workflow** (`.github/workflows/ci.yml`)
   - Terraform validation and linting
   - Security scanning with tfsec
   - Provider compatibility testing
   - **Requires**: Azure authentication for `terraform plan` jobs

2. **Nightly Validation** (`.github/workflows/nightly-validation.yml`) 
   - API version checks
   - Provider update monitoring
   - Test deployments
   - **Requires**: Full Azure authentication

3. **Release Workflow** (`.github/workflows/release.yml`)
   - Automated releases and changelog generation
   - Documentation updates
   - **Requires**: GitHub authentication only

### Authentication Flow

```mermaid
graph TB
    A[GitHub Action Triggered] --> B{Requires Azure?}
    B -->|Yes| C[Load Azure Secrets]
    B -->|No| F[Run Without Azure Auth]
    C --> D[azure/login@v2 Action]
    D --> E[Terraform Plan/Deploy]
    E --> G[Success]
    F --> G
```

---
### Required Secrets Summary

| Secret | Purpose | Example Value |
|--------|---------|---------------|
| `AZURE_CLIENT_ID` | Azure CLI auth | `12345678-1234-1234-1234-123456789012` |
| `AZURE_TENANT_ID` | Azure CLI auth | `11111111-1111-1111-1111-111111111111` |
| `AZURE_SUBSCRIPTION_ID` | Azure CLI auth | `87654321-4321-4321-4321-210987654321` |
| `ARM_CLIENT_ID` | Terraform auth | Same as `AZURE_CLIENT_ID` |
| `ARM_CLIENT_SECRET` | Terraform auth | `your-service-principal-secret` |
| `ARM_TENANT_ID` | Terraform auth | Same as `AZURE_TENANT_ID` |
| `ARM_SUBSCRIPTION_ID` | Terraform auth | Same as `AZURE_SUBSCRIPTION_ID` |

---

**🚀 You're all set!** Your GitHub Codespace and CI/CD workflows should now be fully configured for Azure Managed Redis deployment.
