# Simple Azure Managed Redis Example

This example demonstrates the minimal configuration required to deploy Azure Managed Redis using this module.

## Configuration

- **Cluster**: Balanced_B0 SKU (minimal cost)
- **Database**: Single database with default settings
- **Modules**: None (basic Redis functionality only)
- **High Availability**: Disabled (for cost optimization)
- **TLS**: Version 1.2 (secure default)

## Usage

1. Update the variables in `terraform.tfvars`:

```hcl
resource_group_name = "rg-azure-managed-redis-terraform"
location           = "East US"
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
