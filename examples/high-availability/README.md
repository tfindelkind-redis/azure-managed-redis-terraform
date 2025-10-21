# High Availability Redis Enterprise Example

This example demonstrates an Azure Managed Redis deployment configured for high availability and enhanced performance.

## Configuration Features

### High Availability
- **Multi-AZ Deployment**: Deployed across availability zones 1, 2, and 3
- **Automatic Failover**: Built-in failover capabilities  
- **Data Replication**: Synchronous replication between zones
- **High Availability**: Enhanced uptime configuration

### Performance & Scale
- **Balanced_B3 SKU**: Enhanced performance tier
- **Enterprise Clustering**: Horizontal scaling capability
- **Memory Optimization**: Optimized for high-throughput workloads
- **Low Latency**: Sub-millisecond response times

### Security
- **TLS 1.2 Encryption**: All connections encrypted in transit
- **Secure Access Keys**: Managed through Azure Key Vault integration
- **Network Isolation**: Private networking support
- **Compliance Ready**: SOC, ISO, GDPR compliance

## Architecture

```
┌─────────────────────────────────────────┐
│               Load Balancer              │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────┼───────────────────────┐
│     Availability Zone 1    │    AZ 2    │  AZ 3
│  ┌──────────────┐  ┌───────────┐  ┌─────────┐
│  │ Redis Primary│  │Redis Sync │  │Redis Sync│
│  └──────────────┘  └───────────┘  └─────────┘
└─────────────────────────────────────────────┘
```

## Monitoring & Alerting

This example includes tags for:
- **CriticalLevel**: tier1 for high-priority monitoring
- **MonitoringEnabled**: Integration with Azure Monitor
- **BackupPolicy**: Daily backup retention

### Key Metrics to Monitor
- Memory usage percentage
- Connected clients
- Operations per second  
- Replication lag
- Availability percentage

## Disaster Recovery

### Backup Strategy
- **Automated Backups**: Daily point-in-time backups
- **Cross-Region**: Geo-redundant backup storage
- **Retention**: 30-day backup retention policy

### Recovery Procedures
1. **Zone Failure**: Automatic failover (< 30 seconds)
2. **Region Failure**: Manual failover to secondary region
3. **Data Corruption**: Point-in-time restore from backup

## Usage

1. **Deploy High Availability Environment**:
```bash
terraform init
terraform plan -var="environment=ha"
terraform apply -var="environment=ha"
```

2. **Verify High Availability**:
```bash
# Get connection details
HOSTNAME=$(terraform output -raw hostname)
PORT=$(terraform output -raw port)
PRIMARY_KEY=$(terraform output -raw primary_key)

# Test basic connectivity
redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning ping
# Expected output: PONG

# Test data operations
redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning SET test "ha-test"
redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning GET test
```

3. **Performance Testing**:
```bash
# Run performance benchmark with explicit parameters
redis-benchmark -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" \
  -t set,get -n 100000 -c 50 -d 1024
```

## Cost Optimization

While optimized for availability, consider:
- **Right-sizing**: Monitor actual usage vs. provisioned capacity
- **Reserved Instances**: 1-3 year commitments for cost savings
- **Off-peak Scaling**: Scale down during low-usage periods
- **Module Selection**: Only enable required modules

## Compliance & Security

### Security Checklist
- ✅ TLS 1.2+ encryption
- ✅ Secure key management
- ✅ Network access controls
- ✅ Audit logging enabled
- ✅ Backup encryption

### Compliance Features
- **SOC 2 Type II**: Security controls compliance
- **ISO 27001**: Information security standards
- **GDPR**: Data protection compliance
- **HIPAA**: Healthcare data protection (when configured)

## Next Steps

1. **Set up Monitoring**: Configure Azure Monitor alerts
2. **Implement Backup**: Verify backup and restore procedures
3. **Load Testing**: Validate performance under expected load
4. **Security Hardening**: Implement network security groups
5. **Documentation**: Create runbooks for operational procedures

## Configuration Notes

- **Azure Support**: Available through Azure support plans
- **Availability**: High availability configuration enabled
- **Monitoring**: CloudWatch and Azure Monitor integration
- **Documentation**: Refer to Azure Redis Enterprise documentation
