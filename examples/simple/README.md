# Simple Azure Managed Redis Example

This example demonstrates the minimal configuration required to deploy Azure Managed Redis using this module.

## Provider Support

This example supports **both AzAPI and AzureRM providers**. You can easily switch between them:

- **AzureRM** (default, recommended): Native Terraform support with `azurerm_managed_redis`
- **AzAPI**: Direct Azure ARM API access for preview features

**Switch providers easily:**
```bash
./switch-provider.sh to-azurerm  # Switch to native AzureRM
./switch-provider.sh to-azapi    # Switch to AzAPI
./switch-provider.sh status      # Check current provider
```

See [PROVIDER-SWITCHING.md](./PROVIDER-SWITCHING.md) for detailed documentation.

## Configuration

- **Cluster**: Balanced_B0 SKU (minimal cost)
- **Database**: Single database with default settings
- **Modules**: None (basic Redis functionality only)
- **High Availability**: Disabled (for cost optimization)
- **TLS**: Version 1.2 (secure default)
- **Provider**: AzureRM by default (set `use_azapi = false`)

## Usage

### Prerequisites

Before deploying, ensure you have:

1. **Azure CLI** installed and authenticated:
```bash
az login
az account show  # Verify your subscription
```

2. **Environment variables** set for Terraform:
```bash
# Required for local development
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export ARM_USE_CLI=true

# Verify
echo "Subscription: $ARM_SUBSCRIPTION_ID"
```

> **Note**: GitHub Actions workflows handle authentication automatically via OIDC. 
> Environment variables are only needed for local development.

### Deployment Steps

1. Update the variables in `terraform.tfvars`:

```hcl
resource_group_name = "rg-azure-managed-redis-terraform"
location           = "North Europe"
redis_name         = "redis-simple-demo"
```

2. Initialize and apply:

```bash
terraform init
terraform plan
terraform apply
```

3. Test the connection:

```bash
# Get connection details
HOSTNAME=$(terraform output -raw hostname)
PORT=$(terraform output -raw port)
PRIMARY_KEY=$(terraform output -raw primary_key)

# Test with redis-cli (if installed)
redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning ping
# Expected output: PONG
```

## Outputs

After deployment, you can access:

- Redis hostname: `terraform output hostname`
- Connection string: `terraform output -raw connection_string`
- Access keys: Available as sensitive outputs

## Cost Optimization

This example uses:
- **Balanced_B0**: Lowest cost SKU
- **Single module**: Only RedisJSON enabled
- **No high availability**: Single instance deployment
- **Default region**: Choose region closest to your users

## Next Steps

- See [with-modules example](../with-modules/) for advanced module configuration
- See [high-availability example](../high-availability/) for production setup
- Review [geo-replication example](../geo-replication/) for globally distributed deployments
