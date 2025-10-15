# Migration from Azure Cache for Redis to Azure Managed Redis

This guide helps you migrate from Azure Cache for Redis (classic) or Redis Enterprise (classic) to Azure Managed Redis using this Terraform module.

## Overview

Azure Managed Redis is the next generation of Redis services on Azure, built on Redis Enterprise technology and integrated into Azure's control plane.

### Benefits of Migration

- **Enhanced Performance**: Redis Enterprise engine with better performance characteristics
- **Advanced Modules**: Native support for RedisJSON, RediSearch, RedisBloom, and RedisTimeSeries
- **Simplified Management**: Fully integrated with Azure management tools
- **Better Scaling**: More flexible scaling options and SKU choices
- **Native Integration**: Built into Azure's control plane for consistent experience

## Pre-Migration Assessment

### Current Configuration Audit

1. **Identify Current Resources**:
   ```bash
   # List existing Redis instances
   az redis list --query "[].{Name:name,ResourceGroup:resourceGroup,SKU:sku.name,Location:location}" -o table
   ```

2. **Document Configuration**:
   - SKU and memory size
   - Redis version
   - Enabled features (persistence, clustering, etc.)
   - Network configuration (VNet integration, firewall rules)
   - Access keys and connection strings
   - Monitoring and alerting setup

3. **Data Size Assessment**:
   ```bash
   # Check memory usage
   redis-cli -h your-redis.redis.cache.windows.net -p 6380 -a your-key info memory
   ```

### Application Dependencies

1. **Connection String Inventory**:
   - Identify all applications using the Redis instance
   - Document current connection strings and configurations
   - Plan for connection string updates

2. **Feature Compatibility**:
   - Check if applications use Redis modules
   - Verify command compatibility
   - Review clustering configuration if applicable

## Migration Strategies

### Strategy 1: Direct Migration (Recommended)

Best for: Development/staging environments, small datasets, acceptable downtime windows.

```hcl
# Step 1: Deploy new Azure Managed Redis
module "redis_managed" {
  source = "git::https://github.com/tfindelkind-redis/azure-managed-redis-terraform.git//modules/managed-redis"
  
  name                = "redis-managed-migration"
  resource_group_name = "rg-redis-migration"
  location            = "East US"
  
  # Match or upgrade from current SKU
  sku = "Balanced_B3"  # Upgrade from Premium P1
  
  # Enable modules if needed
  modules = [
    "RedisJSON",
    "RediSearch"
  ]
  
  high_availability   = true
  minimum_tls_version = "1.2"
  
  tags = {
    Environment = "production"
    Migration   = "from-classic"
  }
}

# Step 2: Update application configuration
output "new_connection_string" {
  value     = module.redis_managed.connection_string
  sensitive = true
}
```

### Strategy 2: Blue-Green Migration

Best for: High-availability environments, zero-downtime requirements, large datasets.

```hcl
# Blue (existing) - managed outside Terraform initially
# Green (new) - managed by this module
module "redis_green" {
  source = "git::https://github.com/tfindelkind-redis/azure-managed-redis-terraform.git//modules/managed-redis"
  
  name                = "${var.redis_name}-green"
  resource_group_name = var.resource_group_name
  location            = var.location
  
  sku = var.target_sku
  modules = var.target_modules
  
  high_availability = true
  
  tags = merge(var.tags, {
    Migration = "blue-green"
    Phase     = "green"
  })
}
```

### Strategy 3: Gradual Migration

Best for: Complex applications, multiple Redis instances, phased approach.

```hcl
# Phase 1: Non-critical workloads
module "redis_phase1" {
  source = "git::https://github.com/tfindelkind-redis/azure-managed-redis-terraform.git//modules/managed-redis"
  
  name = "redis-phase1-migration"
  # ... configuration
  
  tags = {
    MigrationPhase = "1"
    Criticality    = "low"
  }
}

# Phase 2: Business-critical workloads
module "redis_phase2" {
  source = "git::https://github.com/tfindelkind-redis/azure-managed-redis-terraform.git//modules/managed-redis"
  
  name = "redis-phase2-migration"
  # ... configuration
  
  tags = {
    MigrationPhase = "2"
    Criticality    = "high"
  }
}
```

## SKU Mapping Guide

### From Azure Cache for Redis

| Classic SKU | Recommended Managed Redis SKU | Notes |
|-------------|------------------------------|-------|
| Basic C0 (250MB) | Balanced_B0 (1GB) | 4x more memory |
| Basic C1 (1GB) | Balanced_B0 (1GB) | Same memory |
| Standard C1 (1GB) | Balanced_B1 (4GB) | HA + 4x memory |
| Standard C2 (2.5GB) | Balanced_B1 (4GB) | HA + more memory |
| Premium P1 (6GB) | Balanced_B3 (26GB) | 4x memory + modules |
| Premium P2 (13GB) | Balanced_B3 (26GB) | 2x memory + modules |
| Premium P3 (26GB) | Balanced_B3 (26GB) | Same + modules |
| Premium P4 (53GB) | Balanced_B5 (120GB) | 2x memory + modules |

### Performance Considerations

- **Balanced SKUs**: Best for general workloads (recommended starting point)
- **Compute Optimized**: For CPU-intensive operations
- **Memory Optimized**: For large datasets with high memory requirements
- **Flash**: Cost-optimized for large datasets with acceptable latency trade-offs

## Data Migration Process

### 1. Using RIOT (Redis Input/Output Tool)

```bash
# Install RIOT
wget https://github.com/redis-developer/riot/releases/download/v2.15.5/riot-standalone-2.15.5.jar

# Migrate data from classic to managed Redis
java -jar riot-standalone-2.15.5.jar \
  -h source-redis.redis.cache.windows.net \
  -p 6380 \
  -a source-password \
  replicate \
  -h target-hostname \
  -p 10000 \
  -a target-password
```

### 2. Using Redis CLI with RDB Export/Import

```bash
# Export from source (if RDB export is enabled)
redis-cli -h source.redis.cache.windows.net -p 6380 -a password --rdb backup.rdb

# Note: Azure Managed Redis doesn't support RDB import directly
# Use RIOT or application-level migration instead
```

### 3. Application-Level Migration

```python
# Python example for gradual migration
import redis

# Connect to both instances
source_redis = redis.Redis(
    host='source.redis.cache.windows.net',
    port=6380,
    password='source-password',
    ssl=True
)

target_redis = redis.Redis(
    host='target-hostname',
    port=10000,
    password='target-password',
    ssl=True
)

# Migrate keys in batches
def migrate_keys_batch(pattern='*', batch_size=1000):
    for key in source_redis.scan_iter(match=pattern, count=batch_size):
        value = source_redis.dump(key)
        ttl = source_redis.ttl(key)
        target_redis.restore(key, ttl if ttl > 0 else 0, value, replace=True)
        print(f"Migrated {key}")

# Run migration
migrate_keys_batch()
```

## Application Configuration Updates

### Connection String Changes

#### Before (Azure Cache for Redis)
```
your-redis.redis.cache.windows.net:6380,password=your-password,ssl=True
```

#### After (Azure Managed Redis)
```
your-managed-redis-hostname:10000,password=your-new-password,ssl=True
```

### Configuration Updates by Language

#### .NET
```csharp
// Before
services.AddStackExchangeRedisCache(options =>
{
    options.Configuration = "your-redis.redis.cache.windows.net:6380,password=your-password,ssl=True";
});

// After
services.AddStackExchangeRedisCache(options =>
{
    options.Configuration = "your-managed-redis-hostname:10000,password=your-new-password,ssl=True";
});
```

#### Node.js
```javascript
// Before
const redis = require('redis');
const client = redis.createClient({
    host: 'your-redis.redis.cache.windows.net',
    port: 6380,
    password: 'your-password',
    tls: {}
});

// After
const client = redis.createClient({
    host: 'your-managed-redis-hostname',
    port: 10000,
    password: 'your-new-password',
    tls: {}
});
```

#### Python
```python
# Before
import redis
r = redis.Redis(
    host='your-redis.redis.cache.windows.net',
    port=6380,
    password='your-password',
    ssl=True
)

# After
r = redis.Redis(
    host='your-managed-redis-hostname',
    port=10000,
    password='your-new-password',
    ssl=True
)
```

## Validation and Testing

### 1. Connectivity Testing
```bash
# Test basic connectivity
redis-cli -h your-managed-redis-hostname -p 10000 -a your-password ping

# Test TLS connectivity
redis-cli -h your-managed-redis-hostname -p 10000 -a your-password --tls ping
```

### 2. Performance Validation
```bash
# Run benchmark against new instance
redis-benchmark -h your-managed-redis-hostname -p 10000 -a your-password \
  -t set,get -n 100000 -c 50 -d 1024
```

### 3. Module Testing (if applicable)
```bash
# Test RedisJSON
redis-cli -h hostname -p 10000 -a password JSON.SET test $ '{"hello":"world"}'
redis-cli -h hostname -p 10000 -a password JSON.GET test

# Test RediSearch
redis-cli -h hostname -p 10000 -a password FT.CREATE idx ON JSON PREFIX 1 doc: SCHEMA $.title AS title TEXT
```

## Rollback Planning

### Terraform State Management
```hcl
# Keep old resources during migration period
resource "azurerm_redis_cache" "legacy" {
  # Keep old configuration
  count = var.keep_legacy ? 1 : 0
  # ... existing configuration
  
  lifecycle {
    prevent_destroy = true
  }
}

module "redis_managed" {
  source = "./modules/managed-redis"
  # New configuration
}
```

### Application Configuration Rollback
1. **Feature Flags**: Use feature flags to switch between Redis instances
2. **DNS Switching**: Use DNS names that can be updated for quick rollback
3. **Load Balancer**: Route traffic between old and new instances during transition

## Post-Migration Tasks

### 1. Update Monitoring
```hcl
# Add Azure Monitor integration
resource "azurerm_monitor_diagnostic_setting" "redis" {
  name               = "redis-diagnostics"
  target_resource_id = module.redis_managed.cluster_id

  log_analytics_workspace_id = var.log_analytics_workspace_id

  log {
    category = "ConnectedClientList"
    enabled  = true
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
```

### 2. Update Alerts
- Migrate existing alerts to new metrics
- Update alert thresholds for new performance characteristics
- Configure Azure Monitor integration

### 3. Documentation Updates
- Update architecture diagrams
- Update connection string documentation
- Update operational runbooks

### 4. Clean Up Legacy Resources
```bash
# After successful migration and validation period
terraform destroy -target=azurerm_redis_cache.legacy
```

## Common Migration Issues

### Issue 1: Port Changes
- **Problem**: Applications hardcoded to use port 6380
- **Solution**: Update all connection configurations to use port 10000

### Issue 2: Command Compatibility
- **Problem**: Some Redis commands behave differently in Redis Enterprise
- **Solution**: Test all application Redis operations in staging environment

### Issue 3: Memory Usage Patterns
- **Problem**: Different memory optimization in Redis Enterprise
- **Solution**: Monitor memory usage and adjust SKU if needed

### Issue 4: Module Dependencies
- **Problem**: Applications expect Redis modules not enabled
- **Solution**: Enable required modules in Terraform configuration

## Support and Resources

### Microsoft Support
- Open Azure support ticket for migration assistance
- Use Azure Database Migration Service if available

### Additional Resources
- [Redis Enterprise Migration Guide](https://docs.redis.com/latest/rs/installing-upgrading/migrating-to-redis-enterprise/)
- [Azure Redis Migration Documentation](https://docs.microsoft.com/en-us/azure/azure-cache-for-redis/cache-migration-guide)

### Professional Services
Consider engaging Redis or Microsoft professional services for:
- Complex migration scenarios
- Large-scale deployments
- Performance optimization
- Custom migration tooling

## Timeline Template

### Phase 1: Planning (Week 1-2)
- [ ] Audit current Redis usage
- [ ] Identify application dependencies  
- [ ] Plan SKU mapping
- [ ] Create migration timeline

### Phase 2: Setup (Week 3)
- [ ] Deploy Azure Managed Redis in staging
- [ ] Configure monitoring and alerting
- [ ] Test application connectivity
- [ ] Validate performance

### Phase 3: Data Migration (Week 4)
- [ ] Migrate staging data
- [ ] Validate data integrity
- [ ] Test application functionality
- [ ] Performance validation

### Phase 4: Production Migration (Week 5-6)
- [ ] Deploy production Azure Managed Redis
- [ ] Schedule maintenance window
- [ ] Execute data migration
- [ ] Update application configuration
- [ ] Validate and monitor

### Phase 5: Optimization (Week 7-8)
- [ ] Performance tuning
- [ ] Cost optimization
- [ ] Documentation updates
- [ ] Clean up legacy resources
