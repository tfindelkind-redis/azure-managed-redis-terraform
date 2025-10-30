# Azure Managed Redis - Clusterless with Persistence Example

This example demonstrates deploying Azure Managed Redis in a clusterless configuration with both RDB and AOF persistence enabled.

## Features Demonstrated

- **Clusterless Deployment**: Single-shard Redis instance using `EnterpriseCluster` policy
- **RDB Persistence**: Point-in-time snapshots for backup and recovery
- **AOF Persistence**: Append-only file for maximum durability
- **High Availability**: Active-passive replication for fault tolerance

## Architecture

```
┌─────────────────────────────────────────────────┐
│  Azure Managed Redis (Clusterless)             │
│  ┌───────────────────────────────────────────┐ │
│  │  Primary Node                             │ │
│  │  - Single Shard                           │ │
│  │  - RDB Snapshots (periodic backups)       │ │
│  │  - AOF Log (every write operation)        │ │
│  └───────────────────────────────────────────┘ │
│                    │                            │
│                    │ Replication                │
│                    ▼                            │
│  ┌───────────────────────────────────────────┐ │
│  │  Replica Node (High Availability)         │ │
│  │  - Auto-failover capability               │ │
│  │  - Data synchronized from primary         │ │
│  └───────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

## Prerequisites

- Azure subscription
- Terraform >= 1.3
- Azure CLI (for authentication)

## Deployment

1. **Configure variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Review the plan**:
   ```bash
   terraform plan
   ```

4. **Deploy**:
   ```bash
   terraform apply
   ```

## Key Configuration

```hcl
module "redis_clusterless" {
  source = "../../modules/managed-redis"
  
  # Clusterless configuration
  clustering_policy = "EnterpriseCluster"  # Single shard, no clustering
  
  # Persistence for data durability
  persistence_rdb_enabled = true  # Periodic snapshots
  persistence_aof_enabled = true  # Log every write
  
  # High availability
  high_availability = true
  
  # Must use AzAPI for persistence features
  use_azapi = true
}
```

## Persistence Options

### RDB (Redis Database Backup)
- **How it works**: Periodic snapshots of the entire dataset
- **Benefits**: 
  - Lower performance overhead
  - Faster restarts
  - Good for disaster recovery
- **Trade-offs**: 
  - Potential data loss between snapshots
  - Less frequent than AOF

### AOF (Append-Only File)
- **How it works**: Logs every write operation
- **Benefits**: 
  - Maximum data durability
  - Minimal data loss (only unflushed data)
  - Every write is persisted
- **Trade-offs**: 
  - Higher I/O overhead
  - Larger file sizes
  - Slower restarts (needs to replay log)

### Combined RDB + AOF (Recommended)
- **Best of both worlds**:
  - AOF for durability (minimal data loss)
  - RDB for faster restarts (point-in-time snapshot)
- **How it works**:
  - AOF logs writes continuously
  - RDB creates periodic snapshots
  - On restart: loads RDB snapshot, then replays AOF log

## Clusterless vs Clustered

| Aspect | Clusterless (EnterpriseCluster) | Clustered (OSSCluster) |
|--------|--------------------------------|------------------------|
| **Shards** | Single shard | Multiple shards |
| **Key Distribution** | All keys on one shard | Keys distributed across shards |
| **Max Memory** | Limited to single node | Scales horizontally |
| **Complexity** | Simple | More complex |
| **Client Support** | All Redis clients | Cluster-aware clients |
| **Use Case** | < 500GB, simple apps | > 500GB, horizontal scaling |

## When to Use Clusterless

Choose clusterless deployment when:
- ✅ Dataset fits in a single node (< 500GB typically)
- ✅ Application doesn't need horizontal scaling
- ✅ Simpler client configuration preferred
- ✅ All Redis commands need to work (some commands don't work in cluster mode)
- ✅ Transactions and Lua scripts need to access any key

## When to Use Clustering

Choose clustered deployment when:
- ✅ Dataset exceeds single node capacity
- ✅ Need horizontal scaling across shards
- ✅ Want to distribute load across multiple nodes
- ✅ Application is cluster-aware

## Monitoring

After deployment, monitor:
- **RDB Status**: Check last successful snapshot time
- **AOF Status**: Verify AOF is writing and compacting properly
- **Memory Usage**: Ensure within capacity limits
- **Replication Lag**: Monitor replica sync status

## Clean Up

```bash
terraform destroy
```

## Switching Providers

To switch between AzAPI and AzureRM providers:

```bash
# Switch to AzureRM (note: will lose persistence settings)
./switch-provider.sh to-azurerm

# Switch back to AzAPI
./switch-provider.sh to-azapi
```

**Note**: Persistence (RDB/AOF) is only supported with AzAPI provider. Switching to AzureRM will disable these features.

## Additional Resources

- [Azure Managed Redis Documentation](https://learn.microsoft.com/en-us/azure/azure-cache-for-redis/managed-redis/)
- [Redis Persistence Documentation](https://redis.io/docs/management/persistence/)
- [Clustering Policy Guide](https://learn.microsoft.com/en-us/azure/azure-cache-for-redis/managed-redis/managed-redis-architecture#clustering-policy)
