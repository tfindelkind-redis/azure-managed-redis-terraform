# GitHub Actions CI/CD Configuration

This repository uses GitHub Actions for continuous integration and validation.

## Workflows

### 1. CI Workflow (`.github/workflows/ci.yml`)

Runs on every push and pull request to validate Terraform code.

**Jobs:**
- **terraform-validate**: Validates syntax and formatting (no Azure credentials needed)
- **terraform-plan**: Attempts to create execution plan (requires Azure credentials)
- **security-scan**: Runs tfsec and trivy security scans
- **lint**: Runs tflint to check for best practices and potential issues

**TFLint Configuration:**
- Repository root has `.tflint.hcl` with default rules for all examples
- Individual examples can override with their own `.tflint.hcl` file
- Example: `examples/enterprise-security/.tflint.hcl` disables the standard module structure rule
- The CI workflow automatically detects and uses local configs when present

**Credential Handling:**
- ✅ **Validation** always runs (format check, terraform validate)
- ⚠️ **Plan** only runs if Azure credentials are configured
- 🔓 For PRs and pushes without credentials, plan step will be skipped or fail gracefully with `continue-on-error: true`

### 2. Nightly Validation (`.github/workflows/nightly-validation.yml`)

Runs weekly (Sundays at 2 AM UTC) to check for:
- API version updates
- Security vulnerabilities
- Example deployments (if enabled)

**Requires Azure credentials to run fully.**

## Setting Up Azure Credentials

To enable full CI functionality (terraform plan), configure these repository secrets:

1. **`AZURE_CLIENT_ID`** - Service Principal client ID
2. **`AZURE_TENANT_ID`** - Azure AD tenant ID  
3. **`AZURE_SUBSCRIPTION_ID`** - Target Azure subscription ID

### Using OIDC (Recommended)

```bash
# Create federated credential for GitHub Actions
az ad app federated-credential create \
  --id <APP_ID> \
  --parameters '{
    "name": "github-actions",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:<OWNER>/<REPO>:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### Using Service Principal (Alternative)

```bash
# Create service principal
az ad sp create-for-rbac \
  --name "github-actions-terraform" \
  --role Contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>
```

## Running Without Azure Credentials

The CI will still run successfully without Azure credentials:

✅ **What works:**
- Terraform formatting checks
- Terraform validation  
- Syntax verification
- Security scans (tfsec, trivy)
- Module validation

⚠️ **What's skipped:**
- Terraform plan generation
- Azure API version checks
- Nightly deployment tests

This allows public forks and development without requiring Azure access!

## Manual Workflow Dispatch

All workflows can be triggered manually via GitHub Actions UI:
- `workflow_dispatch` event type is enabled
- Useful for testing before merging
- Nightly validation can be run on-demand

## Status Badges

Add to your README:

```markdown
![CI](https://github.com/<OWNER>/<REPO>/actions/workflows/ci.yml/badge.svg)
![Nightly](https://github.com/<OWNER>/<REPO>/actions/workflows/nightly-validation.yml/badge.svg)
```
