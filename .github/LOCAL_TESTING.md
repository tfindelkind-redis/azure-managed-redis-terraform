# Local GitHub Actions Testing

Testing GitHub Actions workflows locally without creating multiple commits.

## Tool: `act` 

[nektos/act](https://github.com/nektos/act) runs GitHub Actions locally using Docker.

### Installation

```bash
# macOS
brew install act

# Linux
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Windows
choco install act-cli
```

## Quick Start

### 1. Test Individual Jobs

```bash
# List all available jobs
act -l

# Run the lint job
act -j lint

# Run terraform-validate job
act -j terraform-validate

# Run security-scan job
act -j security-scan
```

### 2. Test Specific Events

```bash
# Test push event (default)
act push

# Test pull request event
act pull_request

# Test workflow_dispatch
act workflow_dispatch
```

### 3. Run Specific Workflow

```bash
# Run only the CI workflow
act -W .github/workflows/ci.yml

# Run nightly validation
act -W .github/workflows/nightly-validation.yml
```

### 4. Dry Run (Check what would run)

```bash
# See what jobs would run without executing
act -n

# See jobs for a specific event
act pull_request -n
```

## Common Use Cases

### Test TFLint Configuration

```bash
# Run just the lint job to test .tflint.hcl changes
act -j lint

# Run with verbose output to debug
act -j lint -v
```

### Test Terraform Validation

```bash
# Run validation across all examples
act -j terraform-validate
```

### Test Matrix Jobs

```bash
# Test a specific matrix combination
act -j terraform-validate --matrix directory:examples/enterprise-security
```

### Skip Jobs That Need Secrets

```bash
# Run everything except jobs requiring Azure credentials
act -j terraform-validate -j lint -j security-scan
```

## Tips & Tricks

### 1. Speed Up Runs

```bash
# Use smaller Docker images
act --container-architecture linux/amd64 -j lint

# Reuse containers (faster subsequent runs)
act --reuse -j lint
```

### 2. Debug Failures

```bash
# Enable verbose logging
act -j lint -v

# Enable secret masking debug
act -j lint --secret-file .github/.secrets -v

# Run with shell access on failure
act -j lint --bind
```

### 3. Local Secrets (Optional)

If you need to test jobs requiring Azure credentials:

```bash
# Create .github/.secrets file (gitignored)
cat > .github/.secrets << EOF
AZURE_CLIENT_ID=your-client-id
AZURE_TENANT_ID=your-tenant-id
AZURE_SUBSCRIPTION_ID=your-subscription-id
EOF

# Run with secrets
act -j terraform-plan --secret-file .github/.secrets
```

**⚠️ Never commit the `.secrets` file!**

### 4. Platform-Specific Testing

```bash
# Test on specific platform
act --platform ubuntu-latest=ghcr.io/catthehacker/ubuntu:full-latest

# Use official GitHub runner images (slower but accurate)
act --platform ubuntu-latest=ghcr.io/catthehacker/ubuntu:runner-latest
```

## Pre-Commit Testing Script

We've included a helper script for quick pre-commit validation:

```bash
# First time setup - install required tools
./scripts/test-actions-locally.sh install

# Run all validation checks locally before committing
./scripts/test-actions-locally.sh

# Run specific checks
./scripts/test-actions-locally.sh lint
./scripts/test-actions-locally.sh validate
./scripts/test-actions-locally.sh security
```

**Features:**
- ✅ **Auto-install**: Detects missing tools and offers to install them (macOS with Homebrew)
- ✅ **Interactive prompts**: Choose to install now or get manual instructions
- ✅ **Multi-platform support**: Provides installation commands for macOS, Linux, and Windows
- ✅ **Color-coded output**: Easy to read results
- ✅ **Detailed errors**: Shows exactly what failed and where

## Workflow-Specific Commands

### CI Workflow

```bash
# Test the full CI pipeline
act push -W .github/workflows/ci.yml

# Test just formatting and validation
act -j terraform-validate

# Test just linting
act -j lint

# Test just security scanning
act -j security-scan
```

### Debugging TFLint Issues

```bash
# Run lint job with verbose output
act -j lint -v

# Or run tflint directly in examples
for example in examples/*/; do
  echo "Linting $example"
  if [ -f "$example/.tflint.hcl" ]; then
    tflint --chdir="$example"
  else
    tflint --chdir="$example" --config=.tflint.hcl
  fi
done
```

## Limitations

### What Works ✅
- All validation jobs (terraform validate, fmt, tflint)
- Security scanning (tfsec)
- Documentation checks
- Most matrix strategies

### What Doesn't Work ⚠️
- Jobs requiring real Azure credentials (unless you provide secrets)
- OIDC authentication (federated credentials)
- Some GitHub-specific contexts
- Actual deployment/plan (needs real Azure subscription)

## Best Practice Workflow

1. **Make changes** to workflows or code
2. **Test locally** with `act -j <job-name>`
3. **Fix issues** based on local output
4. **Repeat** until tests pass
5. **Commit once** with all fixes
6. **Push** with confidence ✅

## Alternatives to `act`

If `act` doesn't work for your use case:

### 1. Local Validation Scripts

Run the same commands as CI locally:

```bash
# Format check
terraform fmt -check -recursive

# Validation
for dir in modules/managed-redis examples/*/; do
  (cd "$dir" && terraform init -backend=false && terraform validate)
done

# TFLint
tflint --init
tflint --chdir=modules/managed-redis/ --config=.tflint.hcl
for example in examples/*/; do
  if [ -f "$example/.tflint.hcl" ]; then
    tflint --chdir="$example"
  else
    tflint --chdir="$example" --config=.tflint.hcl
  fi
done
```

### 2. Pre-commit Hooks

Install [pre-commit](https://pre-commit.com/) framework:

```bash
pip install pre-commit
pre-commit install
```

Create `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.83.5
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
```

### 3. Make Targets

Create a `Makefile` with common validation tasks:

```makefile
.PHONY: validate lint test

validate:
	@echo "Running Terraform validation..."
	@for dir in modules/managed-redis examples/*/; do \
		(cd $$dir && terraform init -backend=false && terraform validate) || exit 1; \
	done

lint:
	@echo "Running TFLint..."
	@tflint --init
	@tflint --chdir=modules/managed-redis/ --config=.tflint.hcl
	@for example in examples/*/; do \
		if [ -f "$$example/.tflint.hcl" ]; then \
			tflint --chdir="$$example"; \
		else \
			tflint --chdir="$$example" --config=.tflint.hcl; \
		fi \
	done

test: validate lint
	@echo "All tests passed!"
```

Then run: `make test`

## Recommended Setup

For the best local testing experience:

1. **Install `act`** for workflow testing
2. **Install `tflint`** for local linting
3. **Use the helper script** `scripts/test-actions-locally.sh` before commits
4. **Configure VS Code** to run validations on save
5. **Consider pre-commit hooks** for automatic checks

This way you can test everything locally and only push when everything passes! 🎉
