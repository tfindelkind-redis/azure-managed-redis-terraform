# Enterprise Security Example (Private Endpoint + High Availability + CMK + Managed Identity)

This example demonstrates Azure Managed Redis (Redis Enterprise) with **full enterprise-grade security features** using the **native azurerm provider**.

> **✅ New in azurerm v4.50+**: This example uses the new `azurerm_managed_redis` resource which fully supports Customer Managed Keys (CMK) and Managed Identity! The older `azurerm_redis_enterprise_cluster` resource is now deprecated.

## 🔐 Security Features

This example showcases ALL enterprise security features available in the azurerm provider:

### 1. **Customer Managed Keys (CMK)** 🔑 ✅ IMPLEMENTED
- Encryption keys stored in Azure Key Vault (Premium tier)
- Full control over key rotation and lifecycle
- Meets compliance requirements (GDPR, HIPAA, SOC 2, etc.)
- Purge protection and soft delete enabled
- RBAC-based access control

### 2. **Private Link** 🔒 ✅ IMPLEMENTED
- **No public internet access** - cluster is completely private
- Redis accessible only from within the Virtual Network
- Private DNS resolution for seamless connectivity
- Network isolation and enhanced security posture
- Compatible with hybrid cloud and on-premises connectivity

### 3. **Managed Identity** 🆔 ✅ IMPLEMENTED
- No passwords or connection strings stored in code
- Azure AD-based authentication
- Automatic credential rotation
- Two identities:
  - **Redis Identity**: For the Redis cluster itself
  - **Key Vault Identity**: For CMK access
- RBAC role assignments for least-privilege access

### 4. **Additional Security Features** ✅ IMPLEMENTED
- **High Availability**: Enterprise SKU with clustering support
- **TLS encryption**: Encrypted client protocol
- **Redis Modules**: RedisJSON and RediSearch included
- **Resource tagging**: For governance and cost tracking

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Azure Subscription                                         │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │  Virtual Network (10.0.0.0/16)                        │ │
│  │                                                       │ │
│  │  ┌─────────────────────────────────────────────────┐ │ │
│  │  │  Subnet (10.0.1.0/24)                           │ │ │
│  │  │                                                 │ │ │
│  │  │  ┌──────────────────────────────────────────┐  │ │ │
│  │  │  │  Private Endpoint                        │  │ │ │
│  │  │  │  ↓                                       │  │ │ │
│  │  │  │  Redis Enterprise Cluster (PRIVATE)     │  │ │ │
│  │  │  │  - SKU: Enterprise_E10                  │  │ │ │
│  │  │  │  - Zones: 1, 2, 3 (HA)                  │  │ │ │
│  │  │  │  - CMK Encryption                       │  │ │ │
│  │  │  │  - Managed Identities                   │  │ │ │
│  │  │  │  - TLS 1.2                              │  │ │ │
│  │  │  │  - Modules: JSON, Search                │  │ │ │
│  │  │  └──────────────────────────────────────────┘  │ │ │
│  │  └─────────────────────────────────────────────────┘ │ │
│  │                                                       │ │
│  │  ┌─────────────────────────────────────────────────┐ │ │
│  │  │  Private DNS Zone                               │ │ │
│  │  │  privatelink.redisenterprise.cache.azure.net    │ │ │
│  │  └─────────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │  Key Vault (Premium)                                  │ │
│  │  - Customer Managed Key (RSA 2048)                    │ │
│  │  - RBAC Access Control                                │ │
│  │  - Purge Protection Enabled                           │ │
│  │  - Soft Delete (7 days)                               │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │  User-Assigned Managed Identities                     │ │
│  │  ┌─────────────────────────────────────────────────┐  │ │
│  │  │  Redis Identity                                 │  │ │
│  │  │  - Assigned to Redis cluster                    │  │ │
│  │  └─────────────────────────────────────────────────┘  │ │
│  │  ┌─────────────────────────────────────────────────┐  │ │
│  │  │  Key Vault Identity                             │  │ │
│  │  │  - Role: Key Vault Crypto Service Encryption    │  │ │
│  │  │  - Access to CMK for encryption                 │  │ │
│  │  └─────────────────────────────────────────────────┘  │ │
│  └───────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 📋 Prerequisites

### Azure Permissions
You need permissions to create:
- Virtual Networks and Subnets
- Private Endpoints and Private DNS Zones
- Key Vaults (Premium tier)
- Managed Identities
- Redis Enterprise clusters (Enterprise_E10 SKU)
- Role assignments

### Azure Subscription Requirements
- Enterprise SKU quota available
- Subscription must support:
  - Redis Enterprise in selected region
  - Premium Key Vault
  - Multi-zone deployments

### Tools
- **Terraform**: >= 1.7.5
- **Azure CLI**: Latest version
- **Authentication**: Azure CLI login (`az login`)

## 🚀 Quick Start

### Option 1: Modular Deployment (Recommended) ✨

Deploy in phases - perfect for testing and fixing individual components:

```bash
cd examples/enterprise-security
./deploy-modular.sh
```

**Deployment Phases:**
1. 🌐 **Foundation** - Network (VNet + Subnet)
2. 🔐 **Security** - Managed Identities (2x User-Assigned)
3. 🔑 **Encryption** - Key Vault + CMK + Role Assignments
4. 🚀 **Redis** - Enterprise Cache with CMK & Modules (~15-20 min)
5. 🔗 **Private Link** - Private Endpoint + DNS

**Benefits:**
- ✅ Deploy incrementally - test after each phase
- ✅ Skip already-deployed components
- ✅ Fix only what's broken - no need to destroy everything
- ✅ Interactive prompts guide you through

### Option 2: Interactive Fix/Deploy Tool

Manage individual resources with a menu-driven interface:

```bash
./fix-resource.sh
```

**Features:**
- 📊 View current deployment state
- 🔧 Deploy/update specific components
- 🗑️ Destroy specific components
- 🔄 Force recreation (taint + redeploy)
- 📋 View component details
- 📥 Import existing resources

**📖 See [RESOURCE-MANAGEMENT.md](./RESOURCE-MANAGEMENT.md) for detailed workflows and troubleshooting**

### Option 3: Automated Full Deployment

Use the test script for a one-shot deployment:

```bash
./test-local.sh
```

### Option 4: Manual Deployment

```bash
# 1. Create terraform.tfvars
cp terraform.tfvars.example terraform.tfvars

# 2. Edit configuration (customize as needed)
code terraform.tfvars

# 3. Initialize Terraform
terraform init

# 4. Plan deployment
terraform plan

# 5. Apply deployment
terraform apply
```

## 🔧 Configuration

### Provider Support

This example currently uses the **AzureRM provider** exclusively. While other examples in this repository support switching between AzureRM and AzAPI providers using the `use_azapi` variable, this example is optimized for AzureRM.

**Why AzureRM?**
- The `azurerm_managed_redis` resource (introduced in v4.50+) now fully supports all enterprise security features
- All features demonstrated in this example (CMK, Private Link, Managed Identity, Access Policies) work identically in both providers
- The AzureRM provider is the officially recommended approach for Managed Redis
- Simpler implementation and better community support

**Future AzAPI Support**
If you need AzAPI provider support for this example, please see [AZAPI_SUPPORT_PLAN.md](./AZAPI_SUPPORT_PLAN.md) for implementation options and migration paths.

### Key Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `resource_group_name` | Resource group name | `rg-redis-enterprise-security` | No |
| `location` | Azure region | `northeurope` | No |
| `redis_name` | Redis cluster name | `redis-enterprise-secure` | No |
| `sku_name` | Redis SKU (E10+ for CMK) | `Enterprise_E10` | No |
| `zones` | Availability zones | `["1", "2", "3"]` | No |
| `minimum_tls_version` | Minimum TLS version | `"1.2"` | No |
| `enable_modules` | Enable Redis modules | `true` | No |
| `vnet_address_space` | VNet address space | `["10.0.0.0/16"]` | No |
| `redis_subnet_prefix` | Subnet address prefix | `["10.0.1.0/24"]` | No |
| `use_azapi` | Use AzAPI provider | `false` | No (currently not implemented) |

### Example Configuration

```hcl
resource_group_name = "rg-redis-prod-secure"
location            = "westeurope"
redis_name          = "redis-prod-secure-001"
sku_name            = "Enterprise_E20"  # Larger SKU for production
zones               = ["1", "2", "3"]
minimum_tls_version = "1.2"
enable_modules      = true

tags = {
  "Environment" = "production"
  "CostCenter"  = "engineering"
  "Owner"       = "platform-team"
  "Compliance"  = "GDPR-HIPAA"
}
```

## 💰 Cost Considerations

### Monthly Cost Breakdown

| Component | Estimated Monthly Cost | Notes |
|-----------|------------------------|-------|
| **Redis Enterprise E10** | ~$1,450 | 3 zones, high availability |
| **Key Vault Premium** | ~$5 | Customer managed key storage |
| **Private Endpoint** | ~$10 | Per endpoint |
| **VNet** | ~$0 | No charge for VNet itself |
| **Data Transfer** | Variable | Depends on usage |
| **Total** | **~$1,465/month** | Approximate, region-dependent |

### Cost Optimization Tips

- 🔹 **Development/Testing**: Use `Enterprise_E10` or smaller
- 🔹 **Production**: Consider `Enterprise_E20` or higher based on workload
- 🔹 **Regional Pricing**: Costs vary by Azure region
- 🔹 **Reserved Instances**: Not available for Redis Enterprise (as of Oct 2025)
- 🔹 **Auto-scaling**: Not supported; choose appropriate SKU upfront

## 🧪 Testing

### Prerequisites for Testing
Since Redis is deployed with **Private Link only**, you need network access:

**Option 1: Deploy Azure Function (Recommended)** ✨
```bash
# Deploy a lightweight function with VNet integration
./create-test-function.sh

# This will:
# ✅ Create an Azure Function with VNet integration
# ✅ Run comprehensive connectivity tests
# ✅ Validate Private Link DNS resolution
# ✅ Test Redis operations (PING, SET/GET, JSON)
# ✅ Return results via HTTP endpoint

# The function URL will be displayed - just curl it to test!
```

**Option 2: Deploy a Test VM**
```bash
# Deploy a VM in the same VNet
./create-test-vm.sh

# Then SSH to the VM and test from there
```

**Option 3: Use Azure Bastion**
```bash
# Deploy Azure Bastion to securely access resources
# Connect through Bastion to test connectivity
```

**Option 4: VPN or ExpressRoute**
```bash
# Connect your on-premises network to the VNet
# Test from your local machine through the VPN
```

### Test Commands (from within VNet)

```bash
# Get the connection details
PRIMARY_KEY=$(terraform output -raw primary_access_key)
HOSTNAME=$(terraform output -raw hostname)

# Test basic connectivity
redis-cli -h $HOSTNAME -p 10000 --tls -a "$PRIMARY_KEY" --no-auth-warning PING
# Expected: PONG

# Test RedisJSON module
redis-cli -h $HOSTNAME -p 10000 --tls -a "$PRIMARY_KEY" --no-auth-warning \
  JSON.SET user:1 . '{"name":"John","age":30,"city":"Oslo"}'
# Expected: OK

redis-cli -h $HOSTNAME -p 10000 --tls -a "$PRIMARY_KEY" --no-auth-warning \
  JSON.GET user:1
# Expected: {"name":"John","age":30,"city":"Oslo"}

# Test RediSearch module
redis-cli -h $HOSTNAME -p 10000 --tls -a "$PRIMARY_KEY" --no-auth-warning \
  FT.CREATE idx:users ON JSON PREFIX 1 user: SCHEMA $.name AS name TEXT
# Expected: OK

redis-cli -h $HOSTNAME -p 10000 --tls -a "$PRIMARY_KEY" --no-auth-warning \
  FT.SEARCH idx:users "John"
# Expected: Results with user:1
```

## 🔍 Verification

### Verify Security Features

```bash
# Check Customer Managed Key
terraform output customer_managed_key_enabled
# Expected: true

# Check Managed Identities
terraform output managed_identity_redis_id
terraform output managed_identity_keyvault_id

# Check Private Endpoint
terraform output private_ip_address
# Should show a private IP in the 10.0.1.0/24 range

# Check High Availability
terraform output zones
# Expected: ["1", "2", "3"]

# View security summary
terraform output security_features
```

### Verify in Azure Portal

1. **Redis Cluster**:
   - Navigate to the Redis cluster
   - Check "Encryption" blade → should show Customer Managed Key
   - Check "Networking" blade → should show Private Endpoint only
   - Check "Identity" blade → should show User-Assigned Identities

2. **Key Vault**:
   - Navigate to the Key Vault
   - Check "Keys" blade → should show the CMK
   - Check "Access control (IAM)" → should show role assignments

3. **Private Endpoint**:
   - Navigate to the Private Endpoint
   - Check "DNS configuration" → should show private DNS zone
   - Check "Network interface" → should show private IP

## 📊 Outputs

After deployment, the following outputs are available:

| Output | Description | Sensitive |
|--------|-------------|-----------|
| `cluster_id` | Redis cluster resource ID | No |
| `cluster_name` | Redis cluster name | No |
| `hostname` | Redis hostname | No |
| `database_id` | Database resource ID | No |
| `primary_access_key` | Primary access key | **Yes** |
| `secondary_access_key` | Secondary access key | **Yes** |
| `private_ip_address` | Private endpoint IP | No |
| `managed_identity_redis_id` | Redis identity ID | No |
| `managed_identity_keyvault_id` | Key Vault identity ID | No |
| `key_vault_id` | Key Vault resource ID | No |
| `customer_managed_key_id` | CMK resource ID | No |
| `connection_string` | Full connection string | **Yes** |
| `security_features` | Security features summary | No |

### Get Outputs

```bash
# View all outputs
terraform output

# Get specific output
terraform output -raw hostname

# Get sensitive output
terraform output -raw primary_access_key
```

## 🧹 Cleanup

To destroy all resources:

```bash
terraform destroy
```

⚠️ **Warning**: This will delete:
- Redis Enterprise cluster and all data
- Key Vault and encryption keys (purge protection may apply)
- Private Endpoint and DNS zones
- Virtual Network
- Managed Identities
- Resource Group

## 🔧 Troubleshooting

### Issue: Key Vault Access Denied

**Symptom**: Error creating customer managed key

**Solution**:
```bash
# Ensure you have Key Vault Administrator role
az role assignment create \
  --role "Key Vault Administrator" \
  --assignee $(az account show --query user.name -o tsv) \
  --scope $(terraform output -raw key_vault_id)
```

### Issue: Redis Deployment Timeout

**Symptom**: Terraform times out during cluster creation

**Solution**:
- Redis Enterprise clusters take 15-20 minutes to deploy
- Increase timeout in `redis.tf` if needed
- Multi-zone deployments take longer than single-zone

### Issue: Cannot Connect to Redis

**Symptom**: Connection refused or timeout

**Solution**:
- Verify you're connecting from within the VNet
- Private Link blocks all public access
- Check NSG rules on the subnet
- Verify private DNS resolution

### Issue: CMK Encryption Fails

**Symptom**: Error during cluster creation with CMK

**Solution**:
- Ensure Key Vault has purge protection enabled
- Verify managed identity has correct role assignment
- Check that Key Vault allows the identity's access
- Confirm SKU is Enterprise_E10 or higher (CMK requirement)

## 📚 References

### Official Documentation
- [Azure Managed Redis](https://learn.microsoft.com/azure/azure-cache-for-redis/managed-redis/managed-redis-overview)
- [Azure Private Link](https://learn.microsoft.com/azure/private-link/)
- [Customer Managed Keys](https://learn.microsoft.com/azure/azure-cache-for-redis/cache-how-to-encryption)
- [Managed Identities](https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/)
- [Terraform azurerm Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

### Related Examples
- [Simple Example](../simple/) - Basic Redis deployment
- [High Availability Example](../high-availability/) - HA configuration without security features
- [With Modules Example](../with-modules/) - Redis modules showcase
- [Geo-Replication Example](../geo-replication/) - Global deployment

## 🤝 Contributing

Found an issue or have a suggestion? Please open an issue or pull request!

## 📄 License

MIT License - See [LICENSE](../../LICENSE) for details
