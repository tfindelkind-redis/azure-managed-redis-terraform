# 🔐 OIDC Setup Summary & Admin Request

## 📋 What We're Trying to Accomplish

We are setting up **Azure Workload Identity (OIDC)** to enable secure, automated authentication between **GitHub Actions** and **Azure** for deploying Azure Managed Redis infrastructure.

### 🎯 The Goal
Enable GitHub Actions workflows to:
- ✅ Authenticate to Azure **without storing secrets**
- ✅ Deploy Terraform infrastructure to Azure
- ✅ Manage Azure Managed Redis resources
- ✅ Run CI/CD pipelines securely

### 🔧 What We've Already Done
1. ✅ **Created Azure AD Application**: `github-azure-managed-redis-terraform-oidc`
2. ✅ **Application ID**: `536db7b6-5b15-41ee-8071-ea5570d27481`
3. ✅ **Set up OIDC Trust**: GitHub ↔ Azure federated credentials
4. ✅ **Configured GitHub Secrets**: Repository secrets automatically set
5. ✅ **Created Resource Group**: `rg-azure-managed-redis-terraform`

## ⚠️ What Needs Admin Action

### 🔑 Missing Permission
The Azure AD application needs **Contributor** role permissions on the resource group to:
- Deploy Azure Managed Redis clusters
- Create supporting resources (networking, security, etc.)
- Manage resource lifecycle through Terraform

### 🏢 Why Admin Rights Are Required
**Role assignment** is a **privileged operation** that requires:
- `Microsoft.Authorization/roleAssignments/write` permission
- Typically only available to:
  - **Subscription Owners**
  - **User Access Administrators** 
  - **Resource Group Owners**

## 🚀 Admin Action Required

**Request**: Please assign **Contributor** role to our GitHub Actions service principal

### 📋 Details for Your Admin
```bash
# What the admin needs to run:
az role assignment create \
  --assignee 536db7b6-5b15-41ee-8071-ea5570d27481 \
  --role "Contributor" \
  --scope "/subscriptions/04a9ce47-b2fd-4461-a841-787c6192ceb8/resourceGroups/rg-azure-managed-redis-terraform"
```

### 📝 Or via Azure Portal
1. Go to: **Azure Portal** → **Resource Groups** → **rg-azure-managed-redis-terraform**
2. Click: **Access control (IAM)** → **Add** → **Add role assignment**
3. Select: **Contributor** role
4. Assign to: **github-azure-managed-redis-terraform-oidc** (Application ID: `536db7b6-5b15-41ee-8071-ea5570d27481`)

## 🔒 Security Benefits of This Approach

### ✅ Why OIDC is Better Than Service Principal Secrets
| Traditional Approach | OIDC Approach |
|---------------------|---------------|
| ❌ Long-lived secrets stored in GitHub | ✅ No secrets stored anywhere |
| ❌ Manual secret rotation required | ✅ Automatic token refresh |
| ❌ Broad subscription permissions often granted | ✅ Scoped to specific resource group |
| ❌ High security risk if secrets leak | ✅ Short-lived tokens (minutes) |

### 🎯 Principle of Least Privilege
- **Scope**: Limited to `rg-azure-managed-redis-terraform` resource group only
- **Access**: Only from `tfindelkind-redis/azure-managed-redis-terraform` repository
- **Duration**: Tokens expire automatically after workflow completion
- **Audit**: All access is logged and traceable

## 🚀 What Happens After Admin Approval

Once the Contributor role is assigned:
1. ✅ **GitHub Actions workflows** can authenticate to Azure
2. ✅ **Terraform deployments** will work automatically
3. ✅ **CI/CD pipelines** can deploy Redis infrastructure
4. ✅ **No manual intervention** needed for future deployments

## 📞 Contact for Questions
- **Repository**: tfindelkind-redis/azure-managed-redis-terraform
- **Use Case**: Azure Managed Redis Terraform module deployment
- **Security Model**: Azure Workload Identity (OIDC) - Microsoft recommended approach

---

**This setup follows Microsoft's recommended security best practices for GitHub Actions integration with Azure.** 🛡️
