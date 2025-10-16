# 🔐 Authentication Methods for GitHub Workflows

## Overview

This document compares different authentication methods for GitHub Actions to access Azure resources, with a focus on security, ease of use, and maintenance.

## 🎯 Recommended: Azure Workload Identity (OIDC)

### ✅ Benefits
- **No secrets stored** in GitHub repositories
- **Short-lived tokens** that are automatically renewed
- **Repository-specific** trust relationships
- **Branch-specific** access control
- **Resource group scoped** permissions
- **Zero credential rotation** required
- **Audit-friendly** with clear access patterns

### 🔧 How it Works
1. GitHub generates a temporary OIDC token during workflow execution
2. Azure validates the token against pre-configured trust relationships
3. Temporary Azure credentials are issued for the workflow duration
4. Credentials automatically expire after the workflow completes

### 📋 Setup Requirements
- Azure AD Application with federated credentials
- GitHub repository configured with OIDC trust
- Workflow permissions set to `id-token: write`

---

## ⚠️ Traditional: Service Principal with Secrets

### ❌ Drawbacks
- **Long-lived secrets** stored in GitHub
- **Manual secret rotation** required (recommended every 90 days)
- **Higher security risk** if secrets are compromised
- **No automatic expiration** of stored credentials
- **Broader permissions** often granted due to convenience

### ✅ Benefits
- **Simple setup** for basic scenarios
- **Wide compatibility** with older tooling
- **Well-documented** approach

---

## 🏢 Enterprise: Managed Identity (Azure-hosted runners only)

### ✅ Benefits
- **No secrets at all** - uses Azure's identity system
- **Automatic authentication** for Azure-hosted resources
- **Zero maintenance** overhead
- **Highest security** for Azure-native scenarios

### ❌ Limitations
- **Azure-hosted runners only** (not GitHub-hosted)
- **Higher complexity** for setup
- **Additional Azure infrastructure** required

---

## 📊 Comparison Table

| Method | Security | Maintenance | Cost | Setup Complexity |
|--------|----------|-------------|------|------------------|
| **OIDC (Recommended)** | 🟢 Excellent | 🟢 Zero | 🟢 Free | 🟡 Moderate |
| **Service Principal** | 🟡 Good | 🔴 High | 🟢 Free | 🟢 Simple |
| **Managed Identity** | 🟢 Excellent | 🟢 Zero | 🟡 Higher | 🔴 Complex |

---

## 🚀 Implementation Guide

### Option 1: OIDC Authentication (Recommended)

#### 1. Create Azure Resources
```bash
# Variables
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
RESOURCE_GROUP="rg-redis-terraform"
REPO_OWNER="your-github-username"
REPO_NAME="azure-managed-redis-terraform"
APP_NAME="github-redis-terraform"

# Create Azure AD Application
az ad app create --display-name "$APP_NAME"
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)

# Create Service Principal
az ad sp create --id $APP_ID

# Assign scoped permissions (resource group only)
az role assignment create \
  --assignee $APP_ID \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"

# Create federated credentials for main branch
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$REPO_OWNER'/'$REPO_NAME':ref:refs/heads/main",
    "description": "GitHub Actions - Main Branch",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Create federated credentials for pull requests
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-actions-pr",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$REPO_OWNER'/'$REPO_NAME':pull_request",
    "description": "GitHub Actions - Pull Requests",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

#### 2. Configure GitHub Secrets
Add these secrets to your repository:
- `AZURE_CLIENT_ID`: Application (client) ID
- `AZURE_TENANT_ID`: Directory (tenant) ID
- `AZURE_SUBSCRIPTION_ID`: Subscription ID
- `AZURE_RESOURCE_GROUP`: Target resource group name

#### 3. Update Workflow
```yaml
permissions:
  id-token: write  # Required for OIDC
  contents: read

jobs:
  deploy:
    steps:
    - name: Azure CLI Login (OIDC)
      uses: azure/login@v2
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

### Option 2: Service Principal (Legacy)

#### 1. Create Service Principal
```bash
az ad sp create-for-rbac \
  --name "terraform-redis-sp" \
  --role "Contributor" \
  --scopes "/subscriptions/$(az account show --query id -o tsv)" \
  --json-auth
```

#### 2. Configure GitHub Secrets
Add these secrets:
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET` ⚠️
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

#### 3. Update Workflow
```yaml
- name: Azure CLI Login (Service Principal)
  uses: azure/login@v2
  with:
    creds: ${{ secrets.AZURE_CREDENTIALS }}
```

---

## 🔒 Security Best Practices

### For OIDC Authentication
1. **Scope permissions** to specific resource groups
2. **Use separate credentials** for different environments
3. **Monitor federated credential usage** in Azure AD logs
4. **Regularly review trust relationships**

### For Service Principal Authentication
1. **Rotate secrets regularly** (every 90 days)
2. **Use least privilege permissions**
3. **Monitor secret access** in GitHub audit logs
4. **Consider migrating to OIDC** for better security

---

## 🔍 Troubleshooting

### OIDC Issues
- **Token validation failed**: Check subject claim matches your repository
- **Permission denied**: Verify role assignments and scope
- **Workflow permissions**: Ensure `id-token: write` is set

### Service Principal Issues
- **Authentication failed**: Check secret expiration
- **Permission denied**: Verify role assignments
- **Secret rotation**: Update GitHub secrets when rotating

---

## 📚 Additional Resources

- [Azure Workload Identity Documentation](https://docs.microsoft.com/en-us/azure/active-directory/workload-identities/)
- [GitHub OIDC with Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- [Azure CLI Login Action](https://github.com/azure/login)
