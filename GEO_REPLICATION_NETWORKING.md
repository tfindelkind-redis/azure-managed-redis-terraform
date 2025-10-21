# Azure Managed Redis Geo-Replication Networking Guide

## Question: Do the clusters need special networking to talk to each other?

**Short Answer: NO! Azure Managed Redis handles all cross-region communication automatically. ✅**

## Key Findings

### 1. **Azure Managed Redis vs Azure Cache for Redis (Legacy)**

Our Terraform module uses **Azure Managed Redis** (the new service), NOT the legacy "Azure Cache for Redis":

- **Azure Managed Redis**: Uses `Microsoft.Cache/redisEnterprise` API
- **Legacy Service**: Uses `Microsoft.Cache/Redis` API (being retired)

This is an important distinction because the networking requirements are different!

### 2. **Automatic Cross-Region Connectivity**

For **Azure Managed Redis with Active Geo-Replication**:

✅ **NO VNet peering required**  
✅ **NO VPN Gateway required**  
✅ **NO special firewall rules between regions**  
✅ **NO manual networking configuration needed**

The service handles all cross-region replication communication automatically over Azure's backbone network.

### 3. **What Our Configuration Does**

Looking at our `examples/geo-replication/main.tf`:

```terraform
# Secondary database with geo-replication configuration
resource "azapi_resource" "secondary_database" {
  # ...
  body = {
    properties = {
      # Geo-replication configuration
      geoReplication = {
        groupNickname = var.geo_replication_group_name
        linkedDatabases = [
          {
            id = module.redis_primary.database_id  # Just reference the ID!
          }
        ]
      }
    }
  }
}
```

By simply **referencing the primary database ID**, Azure automatically:
1. Sets up secure communication channels between regions
2. Manages data replication over the Azure backbone
3. Handles authentication and authorization between instances
4. Provides eventual consistency across all linked databases

### 4. **When You DO Need Networking Configuration**

You ONLY need networking configuration if you're using:

#### Legacy "Azure Cache for Redis" with VNet Injection (NOT our case):
- ❌ Requires VNet peering or VPN Gateway for cross-region
- ❌ Requires specific NSG rules (ports 15000-15999)
- ❌ Complex networking setup

#### Azure Managed Redis with Private Endpoints (Optional):
- ✅ Private endpoints are per-region for client connectivity
- ✅ Geo-replication still works automatically
- ✅ Clients connect to their local private endpoint
- ✅ Cross-region replication happens automatically

### 5. **Our Current Setup**

In our geo-replication example:
- **Primary Region**: germanywestcentral (from tfvars)
- **Secondary Region**: westeurope (from tfvars)
- **Resource Groups**: Separate RGs per region
- **Networking**: Public endpoints (default)
- **Cross-Region Communication**: Automatic ✅

### 6. **What Happens During Deployment**

```
1. Primary cluster deploys in germanywestcentral
   └─ Creates cluster + database
   
2. Secondary cluster deploys in westeurope
   └─ Creates cluster
   
3. Secondary database links to primary
   └─ Azure automatically configures replication
   └─ Data starts syncing (eventual consistency)
   
4. Both regions operational
   └─ Clients connect to their nearest region
   └─ Writes to either region replicate to both
```

### 7. **Important Considerations**

✅ **Data Transfer Costs**: Cross-region data transfer is charged at standard bandwidth rates

✅ **Eventual Consistency**: The service does NOT provide SLA on sync time
   - Design your system to handle eventual consistency
   - Don't rely on instant data sync across regions

✅ **Access Keys**: Each cache has its own access key
   - Our test script correctly extracts keys separately for each region
   - Applications need to know both keys if failing over

✅ **Active-Active Configuration**: 
   - Both regions accept reads AND writes
   - Uses CRDTs (Conflict-free Replicated Data Types) for conflict resolution
   - Different from active-passive legacy geo-replication

### 8. **Test Script Validates Connectivity**

Our `test-local.sh` script tests:
1. ✅ Primary region connectivity (PING, SET, JSON operations)
2. ✅ Secondary region connectivity (PING, SET, JSON operations)
3. ✅ RedisJSON module in both regions
4. ✅ RediSearch module in both regions
5. ⏱️ Data replication between regions (with wait time)

### 9. **Configuration Requirements**

For geo-replication to work, you only need:

1. **Both clusters must exist** ✅ (our Terraform handles this)
2. **Proper dependency chain** ✅ (secondary depends on primary)
3. **Linked database configuration** ✅ (geoReplication block)
4. **Same subscription** ✅ (recommended, not strictly required)
5. **Same SKU tier** (not required but recommended for consistency)

### 10. **Private Endpoint Scenario (Future)**

If you add private endpoints later:

```
Region 1 (Primary)                    Region 2 (Secondary)
├─ VNet 1                             ├─ VNet 2
│  ├─ Private Endpoint                │  ├─ Private Endpoint
│  └─ Client Apps connect here        │  └─ Client Apps connect here
│                                     │
└─ Redis Primary Instance ────────────┴─ Redis Secondary Instance
   (Automatic replication over Azure backbone - NO VNet peering needed)
```

## Conclusion

**You can proceed with deployment without any networking concerns!** ✅

The geo-replication configuration in our Terraform module is complete and correct. Azure Managed Redis handles all cross-region communication automatically. The clusters will be able to talk to each other out of the box.

## References

- [Configure active geo-replication for Azure Managed Redis](https://learn.microsoft.com/en-us/azure/redis/how-to-active-geo-replication)
- [Azure Managed Redis architecture](https://learn.microsoft.com/en-us/azure/redis/architecture)
- [Active-Active geo-distribution (CRDTs)](https://redis.io/active-active/)

## Next Steps

1. ✅ Run the test script: `cd examples/geo-replication && bash test-local.sh`
2. ✅ Verify both regions are accessible
3. ✅ Test data replication
4. ✅ Validate RedisJSON and RediSearch in both regions
5. ✅ Clean up with `terraform destroy` when done
