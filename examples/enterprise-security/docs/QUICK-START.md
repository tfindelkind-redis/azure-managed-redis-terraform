# Enterprise Security Example - Quick Reference

This example demonstrates deploying Azure Managed Redis with enterprise-grade security features.

## 📁 Project Structure

```
enterprise-security/
├── 📄 *.tf                    # Terraform configuration files
├── 📄 terraform.tfvars.example
│
├── 📁 scripts/                # All deployment & utility scripts
│   ├── deploy-modular.sh      # ⭐ Main phased deployment
│   ├── run-app-locally.sh     # Run testing app locally
│   ├── check-app-syntax.sh    # Validate Flask app
│   └── ...                    # Other utilities
│
├── 📁 testing-app/            # Flask Redis Testing Application
│   ├── app.py                 # Web UI + REST API
│   ├── requirements.txt       # Python dependencies
│   ├── templates/             # HTML templates
│   └── ...                    # More app files
│
└── 📁 docs/                   # Documentation
    ├── TESTING-APP-PLAN.md    # App architecture
    └── RESOURCE-MANAGEMENT.md # Cleanup guide
```

## 🚀 Quick Start

### 1. Configure
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit with your values
```

### 2. Deploy (Phased)
```bash
./scripts/deploy-modular.sh
```

Deploys in 6 phases:
1. **Network** - VNet, Subnet
2. **Identity** - Managed Identity
3. **Key Vault** - CMK storage
4. **Redis** - Cache instance (~$400/month)
5. **Private Link** - Private endpoint
6. **Testing App** - Web UI (~$70/month)

### 3. Test Locally
```bash
./scripts/run-app-locally.sh
# Visit http://localhost:5000
```

## 🎯 Core Files (What You Need to Understand)

| File | Purpose |
|------|---------|
| `main.tf` | Resource Group |
| `network.tf` | VNet & Subnet |
| `identity.tf` | Managed Identity |
| `keyvault.tf` | Key Vault + CMK |
| `redis.tf` | Redis Cache |
| `app-service.tf` | Testing App |
| `variables.tf` | Configuration inputs |
| `outputs.tf` | Results after deployment |

## 🔐 Security Features

- ✅ **Customer Managed Keys (CMK)** - Your encryption keys
- ✅ **Private Link** - No public internet access
- ✅ **Managed Identity** - No passwords in code
- ✅ **VNet Integration** - Network isolation
- ✅ **Key Vault** - Secrets management
- ✅ **TLS Encryption** - Encrypted connections

## 💰 Cost Estimate

| Resource | Monthly Cost |
|----------|-------------|
| Redis (Balanced_B3) | ~$400 |
| App Service (S1) | ~$70 |
| Key Vault | ~$5 |
| Other | ~$10 |
| **Total** | **~$485** |

💡 **Tip**: Skip Redis deployment for cheaper testing (~$85/month)

## 📚 Full Documentation

For complete details, see the full README and docs in the `docs/` folder.

## 🧪 Testing App

The `testing-app/` folder contains a complete Flask web application with:
- Modern Bootstrap 5 web UI
- Real-time Redis connection monitoring
- Comprehensive test suite
- Performance benchmarks
- REST API with authentication

**Preview locally**: `./scripts/run-app-locally.sh`

## 🔧 Common Tasks

```bash
# Deploy everything
./scripts/deploy-modular.sh

# Check syntax before deploy
./scripts/check-app-syntax.sh

# Test app locally
./scripts/run-app-locally.sh

# Destroy everything
terraform destroy
```

## 📖 Learn More

- Full architecture details in main README (scroll down)
- Testing app documentation: `docs/TESTING-APP-PLAN.md`
- Resource management: `docs/RESOURCE-MANAGEMENT.md`
