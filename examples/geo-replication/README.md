# Geo-Replication Redis Enterprise Example

This example demonstrates deploying Azure Managed Redis with active geo-replication across multiple Azure regions for global applications requiring high availability and disaster recovery capabilities.

## Architecture Overview

```
┌─────────────────┐       ┌─────────────────┐
│   Primary       │◄─────►│   Secondary     │
│   North Europe  │  Geo  │   West Europe   │
│                 │  Rep  │                 │
│ ┌─────────────┐ │       │ ┌─────────────┐ │
│ │    Redis    │ │       │ │    Redis    │ │
│ │ Enterprise  │ │       │ │ Enterprise  │ │
│ │   Cluster   │ │       │ │   Cluster   │ │
│ │             │ │       │ │             │ │
│ │ AZ: 1,2,3   │ │       │ │ AZ: 1,2,3   │ │
│ └─────────────┘ │       │ └─────────────┘ │
└─────────────────┘       └─────────────────┘
        │                         │
        └─────────────┬───────────┘
                      │
              Application Layer
             (Geo-Replicated)
```

## Features

### Geo-Replication
- **Active Geo-Replication**: Data replicated between regions
- **Geo-Replication Group**: Named group for linked databases
- **Automatic Synchronization**: Changes propagate across regions
- **Availability Zones**: Deployed across 3 AZs in each region
- **Production SKU**: Balanced_B3 for high performance

### Disaster Recovery
- **RTO Target**: Recovery Time Objective through geo-replication
- **RPO Target**: Near-zero data loss with active replication
- **Health Monitoring**: Endpoints for health checks in both regions
- **Automatic Failover**: Built-in failover capabilities

### Security & Compliance
- **TLS Encryption**: All connections encrypted
- **Network Isolation**: Separate resource groups per region
- **Access Control**: Individual access keys per cluster
- **Compliance Tags**: Environment and criticality tagging

## Deployment

### 1. Basic Geo-Replication Setup
```bash
terraform init
terraform plan \
  -var="project_name=myapp" \
  -var="primary_location=North Europe" \
  -var="secondary_location=West Europe"
terraform apply
```

### 2. Custom Regions
```bash
terraform apply \
  -var="primary_location=Southeast Asia" \
  -var="secondary_location=Australia East" \
  -var="redis_sku=Balanced_B5"
```

### 3. Production Deployment
```bash
terraform apply \
  -var="project_name=prod-redis" \
  -var="environment=production" \
  -var="redis_sku=MemoryOptimized_M10"
```

## Application Integration

### Connection Configuration

#### Primary-Secondary Pattern
```python
# Python example
import redis
import time

class MultiRegionRedis:
    def __init__(self):
        self.primary = redis.Redis(
            host='primary-hostname',
            port=10000,
            password='primary-key',
            ssl=True,
            socket_timeout=5,
            socket_connect_timeout=5
        )
        self.secondary = redis.Redis(
            host='secondary-hostname', 
            port=10000,
            password='secondary-key',
            ssl=True,
            socket_timeout=5,
            socket_connect_timeout=5
        )
        self.use_primary = True
    
    def get(self, key):
        try:
            if self.use_primary:
                return self.primary.get(key)
            else:
                return self.secondary.get(key)
        except redis.RedisError:
            # Failover to other region
            self.use_primary = not self.use_primary
            return self.get(key)
    
    def set(self, key, value):
        # Write to both regions for consistency
        try:
            self.primary.set(key, value)
            self.secondary.set(key, value)
        except redis.RedisError as e:
            print(f"Write error: {e}")
            # Implement retry logic
```

#### Node.js Example
```javascript
const redis = require('redis');

class MultiRegionRedis {
    constructor() {
        this.primary = redis.createClient({
            host: 'primary-hostname',
            port: 10000,
            password: 'primary-key',
            tls: {},
            connect_timeout: 5000,
            command_timeout: 3000
        });
        
        this.secondary = redis.createClient({
            host: 'secondary-hostname',
            port: 10000, 
            password: 'secondary-key',
            tls: {},
            connect_timeout: 5000,
            command_timeout: 3000
        });
        
        this.currentClient = this.primary;
    }
    
    async get(key) {
        try {
            return await this.currentClient.get(key);
        } catch (error) {
            // Failover
            this.currentClient = this.currentClient === this.primary ? 
                this.secondary : this.primary;
            return await this.currentClient.get(key);
        }
    }
}
```

### Health Check Implementation

```bash
#!/bin/bash
# Health check script for load balancer

PRIMARY_HOST="primary-hostname:10000"
SECONDARY_HOST="secondary-hostname:10000"

check_redis() {
    local host=$1
    local auth=$2
    redis-cli -h ${host%:*} -p ${host#*:} -a "$auth" --no-auth-warning ping 2>/dev/null | grep -q "PONG"
}

if check_redis "$PRIMARY_HOST" "$PRIMARY_KEY"; then
    echo "PRIMARY_HEALTHY"
    exit 0
elif check_redis "$SECONDARY_HOST" "$SECONDARY_KEY"; then
    echo "SECONDARY_HEALTHY"  
    exit 0
else
    echo "BOTH_DOWN"
    exit 1
fi
```

## Monitoring Setup

### Azure Monitor Integration
```hcl
# Add to main.tf for monitoring
resource "azurerm_monitor_metric_alert" "redis_primary_memory" {
  name                = "${var.project_name}-primary-memory-alert"
  resource_group_name = azurerm_resource_group.primary.name
  scopes              = [module.redis_primary.cluster_id]

  criteria {
    metric_namespace = "Microsoft.Cache/redisEnterprise"
    metric_name      = "UsedMemoryPercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
}

resource "azurerm_monitor_metric_alert" "redis_secondary_memory" {
  name                = "${var.project_name}-secondary-memory-alert" 
  resource_group_name = azurerm_resource_group.secondary.name
  scopes              = [module.redis_secondary.cluster_id]

  criteria {
    metric_namespace = "Microsoft.Cache/redisEnterprise"
    metric_name      = "UsedMemoryPercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
}
```

### Prometheus Monitoring
```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'redis-primary'
    static_configs:
      - targets: ['primary-hostname:10000']
    metrics_path: /metrics
    
  - job_name: 'redis-secondary'
    static_configs:
      - targets: ['secondary-hostname:10000']
    metrics_path: /metrics
```

## Disaster Recovery Procedures

### 1. Planned Failover
```bash
# 1. Drain traffic from primary
# 2. Ensure data consistency
# 3. Update DNS or load balancer
# 4. Verify secondary is handling traffic
# 5. Monitor performance
```

### 2. Emergency Failover
```bash
# Automated failover script
#!/bin/bash
PRIMARY_DOWN=$(check_redis_health primary)
if [ "$PRIMARY_DOWN" = "true" ]; then
    # Update DNS to point to secondary
    az network dns record-set a update \
        --resource-group dns-rg \
        --zone-name yourdomain.com \
        --name redis \
        --set aRecords[0].ipv4Address=$(get_secondary_ip)
    
    # Notify operations team
    send_alert "Redis failover executed: Primary -> Secondary"
fi
```

### 3. Recovery Procedures
```bash
# After primary region is restored
# 1. Verify primary cluster health
# 2. Sync data from secondary to primary
# 3. Gradually shift traffic back
# 4. Monitor for issues
# 5. Update documentation
```

## Cost Optimization

### Regional SKU Selection
- **Primary Region**: Higher SKU for primary workload
- **Secondary Region**: Can use smaller SKU for standby
- **Traffic Patterns**: Consider data transfer costs between regions
- **Reserved Capacity**: Use Azure Reserved Instances for predictable workloads

### Cost Monitoring
```hcl
resource "azurerm_consumption_budget" "redis_budget" {
  name            = "${var.project_name}-redis-budget"
  resource_group_id = azurerm_resource_group.primary.id

  amount     = 1000
  time_grain = "Monthly"

  time_period {
    start_date = "2024-01-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "EqualTo"
    threshold_type = "Actual"
    contact_emails = ["admin@yourdomain.com"]
  }
}
```

## Testing

### 1. Deploy and Validate
```bash
# Deploy infrastructure
terraform apply

# Get connection details for primary region
PRIMARY_HOSTNAME=$(terraform output -raw primary_hostname)
PRIMARY_KEY=$(terraform output -raw primary_key)
PORT=10000

# Test primary region
redis-cli -h "$PRIMARY_HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning ping

# Get connection details for secondary region
SECONDARY_HOSTNAME=$(terraform output -raw secondary_hostname)
SECONDARY_KEY=$(terraform output -raw secondary_key)

# Test secondary region  
redis-cli -h "$SECONDARY_HOSTNAME" -p "$PORT" --tls -a "$SECONDARY_KEY" --no-auth-warning ping
```

### 2. Failover Testing
```bash
# Simulate primary failure
# (This is for testing only - don't run in production)
PRIMARY_HOST=$(terraform output -raw primary_hostname)
# Block traffic to primary and test secondary response
```

### 3. Performance Testing
```bash
# Test primary region
echo "Testing primary region..."
redis-benchmark -h "$PRIMARY_HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" -t set,get -n 10000 -c 50

# Test secondary region
echo "Testing secondary region..."
redis-benchmark -h "$SECONDARY_HOSTNAME" -p "$PORT" --tls -a "$SECONDARY_KEY" -t set,get -n 10000 -c 50
```

## Security Considerations

### Network Security
- Consider VNet integration for additional security
- Implement private endpoints where possible
- Use Azure Private DNS for internal name resolution
- Configure NSGs appropriately

### Access Control
- Rotate access keys regularly
- Use Azure Key Vault for key management
- Implement least-privilege access
- Monitor access patterns

### Compliance
- Enable audit logging
- Configure data retention policies  
- Implement backup procedures
- Document security controls

## Limitations & Future Enhancements

### Current Limitations
- No native geo-replication (application-level required)
- Manual failover processes
- Data consistency managed by application
- No automatic traffic management

### Planned Enhancements
- Azure Traffic Manager integration (when supported)
- Native geo-replication (when available)
- Automated failover capabilities
- Cross-region backup and restore

## Next Steps

1. **Deploy Infrastructure**: Use this example as a starting point
2. **Implement Application Logic**: Add multi-region support to applications
3. **Setup Monitoring**: Configure alerts and dashboards
4. **Test Failover**: Validate disaster recovery procedures
5. **Optimize Costs**: Monitor usage and adjust SKUs as needed
6. **Document Procedures**: Create runbooks for operations team

This multi-region setup provides a foundation for globally distributed applications requiring high availability and disaster recovery capabilities.
