# Redis Configuration Comparison

This document explains the differences between the **enterprise-security** example and other examples.

## 🎯 Enterprise Security Example (Current)

**Focus**: Security features (CMK, Private Link, Managed Identity)

```hcl
resource "azurerm_managed_redis" "main" {
  name                = var.redis_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  sku_name            = var.sku_name

  # ✅ SECURITY FEATURES (Explicitly Configured)
  identity {
    type = "UserAssigned"
    identity_ids = [...]
  }

  customer_managed_key {
    key_vault_key_id          = azurerm_key_vault_key.redis.id
    user_assigned_identity_id = azurerm_user_assigned_identity.keyvault.id
  }

  default_database {
    client_protocol   = "Encrypted"      # ✅ Set
    clustering_policy = "EnterpriseCluster"  # ✅ Set
    eviction_policy   = "NoEviction"     # ✅ Set
    
    dynamic "module" {
      for_each = var.enable_modules ? ["RedisJSON", "RediSearch"] : []
      content {
        name = module.value
      }
    }
  }
}
```

### ⚙️ What Uses Defaults?

| Setting | Status | Default Value | Why Default? |
|---------|--------|--------------|--------------|
| **Explicitly Set** | | | |
| `sku_name` | ✅ Set | `Balanced_B3` (via variable) | Core requirement |
| `client_protocol` | ✅ Set | `"Encrypted"` | Security focus |
| `clustering_policy` | ✅ Set | `"EnterpriseCluster"` | Enterprise features |
| `eviction_policy` | ✅ Set | `"NoEviction"` | Production safety |
| `identity` | ✅ Set | User-Assigned | CMK requirement |
| `customer_managed_key` | ✅ Set | Custom CMK | Security focus |
| **Uses Defaults** | | | |
| `zones` | 🔵 Default | `null` (auto in supported regions) | Let Azure decide |
| `shard_count` | 🔵 Default | Based on SKU | Appropriate for SKU |
| `access_keys_authentication` | 🔵 Default | `"Enabled"` | Standard access |
| `port` | 🔵 Default | `10000` | Standard port |
| `linked_server_id` | 🔵 Default | `null` | No geo-replication |
| Database settings: | | | |
| - `aof_backup_enabled` | 🔵 Default | `false` | Not needed for basic setup |
| - `rdb_backup_enabled` | 🔵 Default | `false` | Not needed for basic setup |

---

## 📊 Comparison with Other Examples

### **Simple Example** (Minimal Configuration)

```hcl
module "redis_enterprise" {
  source = "../../modules/managed-redis"

  sku                 = "Balanced_B0"  # Smallest SKU
  modules             = []             # No modules
  high_availability   = false          # Cost optimization
  minimum_tls_version = "1.2"
  client_protocol     = "Encrypted"
}
```

**Sets explicitly**: SKU, modules, HA, TLS, protocol  
**Purpose**: Minimal cost, basic testing

---

### **High Availability Example** (Performance Focus)

```hcl
module "redis_enterprise" {
  source = "../../modules/managed-redis"

  sku                 = "Balanced_B3"   # Production SKU
  modules             = ["RedisJSON"]   # Advanced features
  high_availability   = true            # HA enabled
  minimum_tls_version = "1.2"
  client_protocol     = "Encrypted"
  eviction_policy     = "AllKeysLRU"    # Memory management
}
```

**Sets explicitly**: SKU, modules, HA, TLS, protocol, eviction  
**Purpose**: Production-grade with zone redundancy

---

### **Enterprise Security Example** (Security Focus) ⭐ THIS ONE

```hcl
resource "azurerm_managed_redis" "main" {
  sku_name = var.sku_name

  identity { ... }                     # Managed Identity
  customer_managed_key { ... }         # CMK encryption
  
  default_database {
    client_protocol   = "Encrypted"
    clustering_policy = "EnterpriseCluster"
    eviction_policy   = "NoEviction"
    module { ... }                     # RedisJSON, RediSearch
  }
}
```

**Sets explicitly**: SKU, identity, CMK, protocol, clustering, eviction, modules  
**Purpose**: Enterprise security compliance (GDPR, HIPAA, SOC 2)

---

## 🤔 Why Use Defaults in Enterprise Security?

### 1. **Focus on Security**
The example demonstrates:
- ✅ Customer Managed Keys (CMK)
- ✅ Managed Identity
- ✅ Private Link
- ✅ Key Vault integration

Other settings would **distract** from the security focus.

### 2. **Azure Provider Intelligent Defaults**
The `azurerm_managed_redis` resource has smart defaults:
- **Zones**: Automatically uses availability zones in supported regions
- **Shards**: Appropriate count based on SKU
- **Port**: Standard Redis port (10000)
- **Access**: Standard authentication enabled

### 3. **Production-Safe Defaults**
All defaults are safe for production:
- TLS encryption enabled by default
- Secure protocols
- Appropriate shard counts
- Standard ports

---

## 📝 Available Settings NOT Explicitly Configured

Here are settings you COULD add but use defaults:

```hcl
resource "azurerm_managed_redis" "main" {
  # Currently using defaults for:
  
  zones = ["1", "2", "3"]  # Availability zones
  # Default: Auto-assigned in supported regions
  
  access_keys_authentication = "Enabled"
  # Default: "Enabled"
  
  default_database {
    port = 10000
    # Default: 10000
    
    aof_backup_enabled = false
    aof_backup_frequency = "1h"
    aof_backup_max_snapshot_count = 1
    aof_backup_storage_connection_string = "..."
    # Default: Disabled
    
    rdb_backup_enabled = false
    rdb_backup_frequency = "12h"
    rdb_backup_max_snapshot_count = 1
    rdb_backup_storage_connection_string = "..."
    # Default: Disabled
  }
  
  linked_server_id = null
  # Default: No geo-replication
}
```

---

## 💡 When to Add More Settings

Add explicit configuration when you need:

### **Geo-Replication**
```hcl
linked_server_id = azurerm_managed_redis.secondary.id
```

### **Backup Configuration**
```hcl
default_database {
  rdb_backup_enabled = true
  rdb_backup_frequency = "6h"
  rdb_backup_storage_connection_string = "..."
}
```

### **Custom Availability Zones**
```hcl
zones = ["1", "3"]  # Only specific zones
```

### **Custom Port**
```hcl
default_database {
  port = 11000  # Non-standard port
}
```

### **Different Eviction Policy**
```hcl
default_database {
  eviction_policy = "AllKeysLRU"  # For caching use cases
}
```

---

## ✅ Summary

**Enterprise Security Example Philosophy:**

| Aspect | Approach | Reason |
|--------|----------|--------|
| **Security** | Fully configured | Example purpose |
| **Infrastructure** | Use defaults | Not the focus |
| **Performance** | Use defaults | SKU appropriate |
| **Backup** | Use defaults | Out of scope |
| **Networking** | Fully configured (Private Link) | Security focus |

**Result**: Clean, focused example that shows **exactly what's needed for enterprise security** without overwhelming users with every possible setting.

---

## 🎓 Learning Path

1. **Start here**: `examples/simple` - Minimal configuration
2. **Add features**: `examples/with-modules` - Redis modules
3. **Production ready**: `examples/high-availability` - HA + performance
4. **Full security**: `examples/enterprise-security` - This example ⭐
5. **Global scale**: `examples/geo-replication` - Multi-region

Each example builds on the previous, adding complexity only when needed!
