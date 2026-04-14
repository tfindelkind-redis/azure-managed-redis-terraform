# Azure Cache for Redis (ACR) to Azure Managed Redis (AMR) Migration Plan

> **Document Version**: 1.0  
> **Last Updated**: April 2026  
> **Scope**: Comprehensive migration planning from Azure Cache for Redis (Basic/Standard/Premium/Enterprise) to Azure Managed Redis

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Pre-Migration Checklist](#pre-migration-checklist)
   - [Inventory & Discovery](#1-inventory--discovery)
   - [Feature Compatibility Assessment](#2-feature-compatibility-assessment)
   - [Security Assessment](#3-security-assessment)
   - [Network Assessment](#4-network-assessment)
   - [Application Assessment](#5-application-assessment)
   - [Performance Assessment](#6-performance-assessment)
   - [High Availability & DR Assessment](#7-high-availability--disaster-recovery-assessment)
   - [Data Assessment](#8-data-assessment)
   - [Monitoring & Logging Assessment](#9-monitoring--logging-assessment)
   - [Compliance & Governance Assessment](#10-compliance--governance-assessment)
   - [Cost Assessment](#11-cost-assessment)
   - [Operational Readiness](#12-operational-readiness)
3. [Feature Comparison: ACR vs AMR](#feature-comparison-acr-vs-amr)
4. [Breaking Changes & Blockers](#breaking-changes--blockers)
5. [Migration Strategies](#migration-strategies)
6. [Migration Steps](#migration-steps)
7. [Post-Migration Validation](#post-migration-validation)
8. [Rollback Plan](#rollback-plan)

---

## Executive Summary

Azure Cache for Redis (ACR) has announced retirement for all SKUs. This document provides a comprehensive migration plan to Azure Managed Redis (AMR), covering all corner cases, pre-checks, and potential blockers.

**Key Timeline Considerations:**

| Tier | Retirement Date | Disabled From |
|------|-----------------|---------------|
| Basic, Standard, Premium | **September 30, 2028** | October 1, 2028 |
| Enterprise, Enterprise Flash | **March 31, 2027** | April 1, 2027 |

- All existing ACR instances must be migrated to AMR before retirement
- Microsoft provides migration tooling and guidance
- Existing reservations supported until retirement date

**Critical Differences Summary:**

| Aspect | Impact Level | Key Change |
|--------|--------------|------------|
| Entra ID RBAC | 🔴 **CRITICAL** | ACR Basic/Standard/Premium has Entra ID + Data Access Policies; ACR Enterprise does NOT; AMR has Entra ID auth but NO RBAC yet |
| Multiple Databases | 🔴 **CRITICAL** | ACR non-clustered supports up to 64 DBs; AMR (clustered) only supports database 0 |
| Clustering | 🟡 **HIGH** | AMR is clustered by default; client library changes may be required |
| VNet Injection | 🟡 **HIGH** | ACR Premium deploys Redis inside your VNet subnet; AMR does NOT - must migrate to Private Link |
| DNS/Port | 🟡 **HIGH** | Hostname suffix and port numbers change |
| TLS Mode | 🟡 **HIGH** | ACR supports both TLS/non-TLS simultaneously; AMR is TLS-only (no non-TLS port) |
| Scaling | 🟡 **HIGH** | AMR can scale down only to compatible SKUs (check with `az redisenterprise list-skus-for-scaling`); geo-replicated caches cannot scale down |
| Region Availability | 🟡 **HIGH** | AMR not available in all regions where ACR exists |
| IP Firewall Rules | 🟡 **HIGH** | ACR supports IP-based firewall rules; AMR does NOT - use Private Link + NSG |
| IaC/Terraform | 🟡 **HIGH** | Resource types change: `azurerm_redis_cache` → `azurerm_redis_enterprise_cluster` + `azurerm_redis_enterprise_database` |
| Private DNS Zones | 🟡 **MEDIUM** | ACR: `privatelink.redis.cache.windows.net`; AMR: `privatelink.redis.azure.net` |
| Keyspace Notifications | 🟡 **MEDIUM** | ACR Standard/Premium: ✅ configurable; AMR: ❌ not available - requires application redesign |
| High Availability | 🟢 **ADVANTAGE** | ACR Standard/Premium/Enterprise: HA always on; AMR: HA is optional (cost savings for dev/test) |

**Authentication & RBAC Feature Matrix:**

| Feature | ACR Basic/Standard/Premium | ACR Enterprise | AMR |
|---------|----------------------------|----------------|-----|
| Access Keys | ✅ | ✅ | ✅ |
| Microsoft Entra ID Authentication | ✅ | ❌ | ✅ |
| Data Access Policies (RBAC) | ✅ Data Owner/Contributor/Reader | ❌ | ❌ |
| Disable Access Keys | ✅ | ❌ | ❌ |
| Native Redis ACL command | ❌ Blocked | ❌ Blocked | ❌ Blocked |

> **Official Documentation:**
> - [Use Microsoft Entra for cache authentication](https://learn.microsoft.com/en-us/azure/azure-cache-for-redis/cache-azure-active-directory-for-authentication)
> - [Configure role-based access control with Data Access Policy](https://learn.microsoft.com/en-us/azure/azure-cache-for-redis/cache-configure-role-based-access-control)

---

## Pre-Migration Checklist

### 1. Inventory & Discovery

#### 1.1 Redis Instance Inventory
- [ ] List all ACR instances across all subscriptions
- [ ] Document current tier for each instance (Basic/Standard/Premium/Enterprise/Enterprise Flash)
- [ ] Record instance names, resource groups, and regions
- [ ] **Verify AMR availability in target region** (AMR not available in all ACR regions)
- [ ] Note creation dates and last modification dates
- [ ] Identify instance owners and stakeholders

```bash
# Azure CLI command to list all ACR instances
az redis list --query "[].{name:name, resourceGroup:resourceGroup, location:location, sku:sku.name, family:sku.family, capacity:sku.capacity}" -o table

# For Enterprise tier
az redisenterprise list --query "[].{name:name, resourceGroup:resourceGroup, location:location, sku:sku.name}" -o table
```

#### 1.2 Configuration Audit
- [ ] Document Redis version for each instance (4.0, 6.0, 7.2)
- [ ] Record memory size and capacity
- [ ] List enabled features:
  - [ ] Clustering enabled? (Premium only)
  - [ ] Number of shards
  - [ ] Replica count
  - [ ] Zone redundancy enabled?
  - [ ] Data persistence enabled? (RDB/AOF)
  - [ ] Geo-replication configured?
- [ ] Export current Redis configuration settings:
  - [ ] `maxmemory-policy`
  - [ ] `maxmemory-reserved`
  - [ ] `maxfragmentationmemory-reserved`
  - [ ] `databases` count
  - [ ] `maxclients`
  - [ ] Keyspace notifications settings

#### 1.3 Resource Dependencies

> **Why this matters:** Every service connecting to Redis needs updated connection strings (new hostname, port, potentially auth). Missing a dependent service = production outage after migration.

- [ ] Map all applications connecting to each Redis instance
- [ ] Identify Azure services integrated with Redis:
  - [ ] Azure App Service
  - [ ] Azure Functions
  - [ ] Azure Kubernetes Service (AKS)
  - [ ] Azure Container Apps
  - [ ] Virtual Machines
  - [ ] Logic Apps
  - [ ] Other services
- [ ] Document connection strings storage locations:
  - [ ] Azure Key Vault
  - [ ] App Configuration
  - [ ] Environment variables
  - [ ] Configuration files

---

### 2. Feature Compatibility Assessment

#### 2.1 Redis Commands & Cluster Policy Audit

> **AMR uses Enterprise Cluster Policy by default** - the proxy handles multi-key commands across slots, so CROSSSLOT errors don't occur. This is only relevant if you choose OSS Cluster Policy.

**Cluster Policy Comparison:**

| Aspect | Enterprise Cluster Policy (AMR default) | OSS Cluster Policy |
|--------|----------------------------------------|-------------------|
| Multi-key commands | ✅ Work across slots | ❌ CROSSSLOT errors |
| Client requirements | Any Redis client | Cluster-aware client required |
| `MGET`/`MSET` across slots | ✅ Works | ❌ Fails |
| Transactions across slots | ✅ Works | ❌ Fails |
| Lua scripts across slots | ✅ Works | ❌ Fails |

- [ ] Document current clustering mode (non-clustered ACR vs clustered)
- [ ] **If migrating from non-clustered ACR**: Enterprise Cluster Policy provides seamless compatibility
- [ ] **If choosing OSS Cluster Policy**: Audit multi-key commands and Lua scripts
- [ ] **Note**: AMR Non-Clustered mode limited to ≤25GB; consider clustered mode for larger datasets

#### 2.2 Multiple Databases Assessment ⚠️ **CRITICAL (for non-clustered ACR only)**
- [ ] Check if application uses multiple Redis databases (SELECT command)
- [ ] Document which databases (0-15 or custom) are in use
- [ ] **Note**: Only affects non-clustered ACR (Basic, Standard, Premium without clustering)
- [ ] **Already on Enterprise or clustered Premium?** → Already on single database, no change needed
- [ ] **BLOCKER for non-clustered**: AMR only supports database 0
- [ ] **ACTION REQUIRED if using multiple databases**:
  - [ ] Refactor to use key prefixes instead of multiple databases
  - [ ] Consider using multiple AMR instances
  - [ ] Document data model changes required

```redis
# Check current database usage
INFO keyspace
```

#### 2.3 Redis Modules Assessment
- [ ] Identify if using Redis Enterprise modules:
  - [ ] RediSearch
  - [ ] RedisJSON
  - [ ] RedisBloom
  - [ ] RedisTimeSeries
- [ ] Note: AMR supports all these modules (advantage over ACR Basic/Standard/Premium)
- [ ] Verify module versions compatibility

#### 2.4 Lua Scripting Assessment
- [ ] Inventory all Lua scripts in use
- [ ] Validate scripts work with Redis 7.4 (AMR version)
- [ ] **Only if using OSS Cluster Policy**: Check for cross-slot key access

---

### 3. Security Assessment

> **Important Clarification: Native Redis ACL vs Azure Data Access Policies**
>
> The native Redis ACL command (`ACL SETUSER`, `ACL DELUSER`, `ACL LIST`, etc.) is **BLOCKED in ALL Azure Redis services** - this includes ACR Basic/Standard/Premium, ACR Enterprise, and AMR.
>
> What ACR Basic/Standard/Premium offers instead is **Entra ID + Data Access Policies** - a Microsoft-managed RBAC system that maps Entra ID identities to built-in roles (Data Owner, Data Contributor, Data Reader) or custom permission sets.
>
> ACR Enterprise does **NOT** support Entra ID authentication or Data Access Policies.
>
> **Official Documentation:** [Microsoft Entra for cache authentication](https://learn.microsoft.com/en-us/azure/azure-cache-for-redis/cache-azure-active-directory-for-authentication)

#### 3.1 Authentication Method Audit ⚠️ **CRITICAL**

**Current ACR Tier Support:**
| Tier | Access Keys | Entra ID Auth | Data Access Policies |
|------|-------------|---------------|----------------------|
| ACR Basic | ✅ | ✅ | ✅ |
| ACR Standard | ✅ | ✅ | ✅ |
| ACR Premium | ✅ | ✅ | ✅ |
| ACR Enterprise | ✅ | ❌ | ❌ |
| ACR Enterprise Flash | ✅ | ❌ | ❌ |
| AMR | ✅ | ✅ | ❌ |

- [ ] Document current authentication method:
  - [ ] Access Keys only
  - [ ] Microsoft Entra ID (available for Basic/Standard/Premium only)
  - [ ] Combined (both enabled)
- [ ] **From Microsoft Docs**: "Microsoft Entra authentication isn't supported in the Enterprise tiers of Azure Cache for Redis Enterprise."
- [ ] **IMPORTANT**: AMR supports Entra ID authentication but does NOT support Data Access Policies (RBAC)
- [ ] If using Entra ID + Data Access Policies:
  - [ ] AMR: Entra ID auth works, but no RBAC - all authenticated users have full access
  - [ ] Plan for access key authentication OR accept full access for all Entra users
  - [ ] Update application authentication logic

#### 3.2 Native Redis ACL Assessment ℹ️ **INFO ONLY**

**The native Redis ACL command is BLOCKED in ALL Azure Redis services.**

From Microsoft Docs: "Some Redis commands are blocked. For a full list of blocked commands, see Redis commands not supported in Azure Cache for Redis."

This includes commands like:
- `ACL SETUSER`
- `ACL DELUSER`
- `ACL LIST`
- `ACL CAT`
- `ACL GENPASS`

- [ ] Verify you are NOT relying on native Redis ACL commands (they don't work in ACR either)
- [ ] If migrating from self-hosted Redis with native ACL, you need to redesign authentication approach

#### 3.3 Data Access Policy Assessment ⚠️ **CRITICAL for ACR Basic/Standard/Premium**

**Only applies to ACR Basic, Standard, and Premium tiers.** ACR Enterprise does NOT have this feature.

> **From Microsoft Docs**: "Configuring data access policies isn't supported on Enterprise and Enterprise Flash tiers."
> [Configure custom data access policies](https://learn.microsoft.com/en-us/azure/azure-cache-for-redis/cache-configure-role-based-access-control)

- [ ] Document current Data Access Configuration:
  - [ ] Data Owner assignments (full access)
  - [ ] Data Contributor assignments (read + write, no admin)
  - [ ] Data Reader assignments (read only)
- [ ] List all users/service principals with Redis access
- [ ] Review custom data access policies (permission strings)
- [ ] **MIGRATION IMPACT**: AMR does NOT support Data Access Policies
  - [ ] All Entra-authenticated users will have full access in AMR
  - [ ] Implement application-level access control if needed
  - [ ] Consider multiple AMR instances for isolation

#### 3.4 Encryption Assessment
- [ ] Verify TLS version in use (1.2 or 1.3)
- [ ] Document if non-TLS port (6379) is enabled
- [ ] **IMPORTANT**: AMR supports only ONE mode at a time (TLS or non-TLS)
- [ ] Check client TLS configuration
- [ ] Verify certificate validation settings

#### 3.5 Managed Identity Assessment
- [ ] Document if using System-assigned managed identity
- [ ] Document if using User-assigned managed identity
- [ ] List what managed identities are used for:
  - [ ] Storage account access (for persistence)
  - [ ] Key Vault access
  - [ ] Other Azure services

---

### 4. Network Assessment

#### 4.1 Current Network Configuration
- [ ] Document connectivity method:
  - [ ] Public endpoint
  - [ ] Private Link / Private Endpoint
  - [ ] VNet injection (Premium tier only)
- [ ] **BLOCKER for VNet Injection users**: AMR doesn't support VNet injection
- [ ] **ACTION REQUIRED**: Migrate to Private Link

#### 4.2 VNet Injection Assessment ⚠️ **CRITICAL for ACR Premium with VNet**

> **What is VNet Injection?**
> 
> VNet Injection is a feature **only available in ACR Premium** that deploys Redis nodes **directly into your VNet subnet**. Redis instances get IP addresses from your subnet's address space, giving you full network control with NSGs applying directly to the Redis subnet. Redis becomes part of your VNet topology.
>
> **AMR does NOT support VNet Injection** - you must migrate to Private Link.

**VNet Injection vs Private Link Comparison:**

| Aspect | VNet Injection (ACR Premium) | Private Link (AMR) |
|--------|------------------------------|-------------------|
| Redis location | **Inside** your VNet | Microsoft-managed infrastructure |
| IP assignment | Uses IPs from your subnet | Single Private Endpoint IP |
| NSG application | Directly on Redis subnet | On Private Endpoint subnet |
| UDR support | Yes, full control | Limited |
| Subnet requirement | **Dedicated subnet** required | Endpoint in any subnet |
| On-prem connectivity | ExpressRoute/VPN direct to Redis IPs | Via Private Endpoint |
| Network isolation | Full subnet-level isolation | Endpoint-level isolation |
| Forced tunneling | Supported | Not recommended |

**Migration Impact for VNet Injection Users:**

If you're currently using VNet Injection, you must:

1. **Create Private Endpoints** to the new AMR instance
   - [ ] Plan Private Endpoint deployment in appropriate subnet
   - [ ] Private Endpoint can be in same VNet or different VNet (with peering)

2. **Configure Private DNS zones**
   - [ ] Create/update zone: `privatelink.redis.azure.net` (for AMR)
   - [ ] Link Private DNS zone to all VNets that need access
   - [ ] Update on-premises DNS forwarders if applicable

3. **Update NSG rules**
   - [ ] NSGs now apply to Private Endpoint subnet, not Redis directly
   - [ ] Review and update security rules accordingly
   - [ ] Old Redis subnet NSG rules no longer apply

4. **Update firewall/routing**
   - [ ] Traffic path changes from subnet IPs to Private Endpoint IP
   - [ ] Update any UDR configurations
   - [ ] Review forced tunneling setup

5. **Test on-premises connectivity**
   - [ ] Verify ExpressRoute/VPN can reach new Private Endpoint
   - [ ] Update any on-premises firewall rules
   - [ ] Test DNS resolution from on-premises

**Why organizations used VNet Injection:**
- Strict network isolation requirements
- Full control over Redis network traffic
- Compliance requirements for subnet-level isolation
- Custom routing scenarios (forced tunneling, NVAs)
- Direct integration with existing VNet architecture

**Compensating controls in AMR:**
- Private Link provides network isolation (though different architecture)
- NSGs on Private Endpoint subnet for access control
- Azure Firewall for additional traffic inspection
- Network policies on AKS if connecting from Kubernetes

- [ ] **Document current VNet Injection configuration**
- [ ] **List all applications connecting to VNet-injected Redis IPs**
- [ ] **Plan Private Endpoint migration strategy**
- [ ] **Review compliance implications of architecture change**

#### 4.3 Private Endpoint Assessment
- [ ] List all private endpoints connected to Redis
- [ ] Document Virtual Networks and subnets
- [ ] Note Private DNS zones configured
- [ ] Verify DNS resolution from all client locations

#### 4.4 Firewall Rules Assessment
- [ ] Document all IP-based firewall rules
- [ ] **IMPORTANT**: AMR doesn't support IP-based firewall rules
- [ ] **ACTION REQUIRED**: Use Private Link + NSG instead
- [ ] List allowed IP ranges and their purposes

#### 4.5 VNet Integration Assessment
- [ ] Document current VNet configuration (if Premium with VNet)
- [ ] List NSG rules affecting Redis traffic
- [ ] Note UDR (User Defined Routes) configurations
- [ ] Document ExpressRoute or VPN connections

#### 4.6 Port Requirements
- [ ] Document current ports in use:
  | Component | ACR Port | AMR Port |
  |-----------|----------|----------|
  | TLS endpoint | 6380 | 10000 |
  | Non-TLS endpoint | 6379 | **Not supported** |
  | Cluster node ports | 13XXX/15XXX | 85XX |
- [ ] **BLOCKER if using non-TLS**: AMR requires TLS - migrate all clients to TLS
- [ ] Update firewall rules for new ports
- [ ] Update NSG rules for new ports
- [ ] Verify client applications can connect on new ports

#### 4.7 DNS Requirements
- [ ] Document current DNS suffix: `.redis.cache.windows.net`
- [ ] Plan for new DNS suffix: `.<region>.redis.azure.net`
- [ ] **Private DNS zone change**:
  - ACR: `privatelink.redis.cache.windows.net`
  - AMR: `privatelink.redis.azure.net`
- [ ] Update DNS configurations:
  - [ ] Azure Private DNS zones
  - [ ] On-premises DNS forwarders
  - [ ] Application configuration

---

### 5. Application Assessment

#### 5.1 Client Library Inventory
- [ ] Document all Redis client libraries in use:
  | Application | Language | Library | Version |
  |-------------|----------|---------|---------|
  | App1 | .NET | StackExchange.Redis | x.x.x |
  | App2 | Python | redis-py | x.x.x |
  | App3 | Java | Jedis/Lettuce | x.x.x |
  | App4 | Node.js | node-redis/ioredis | x.x.x |
- [ ] Verify cluster support in each library
- [ ] Check library compatibility with Redis 7.4
- [ ] Identify libraries needing updates

#### 5.2 Connection String Audit
- [ ] Locate all connection string configurations
- [ ] Document connection string format used
- [ ] Identify hardcoded values vs. configuration
- [ ] Plan connection string updates:
  - [ ] Host: `<name>.redis.cache.windows.net` → `<name>.<region>.redis.azure.net`
  - [ ] Port: `6380` → `10000`
  - [ ] SSL parameter adjustments

#### 5.3 Session State Assessment
- [ ] Identify applications using Redis for session state
- [ ] Document session timeout configurations
- [ ] Check session serialization format
- [ ] Plan for session migration/invalidation

#### 5.4 Caching Pattern Assessment
- [ ] Document caching patterns in use:
  - [ ] Cache-aside
  - [ ] Read-through
  - [ ] Write-through
  - [ ] Write-behind
- [ ] Identify cache dependencies
- [ ] Plan cache warming strategy for new instance

#### 5.5 Pub/Sub Usage Assessment
- [ ] Identify applications using Pub/Sub
- [ ] Document channels and patterns
- [ ] Note if using keyspace notifications
- [ ] **IMPORTANT**: Keyspace notifications not available in AMR

---

### 6. Performance Assessment

#### 6.1 Current Metrics Collection
- [ ] Collect baseline metrics (past 30 days minimum):
  - [ ] CPU utilization (peak, average)
  - [ ] Memory usage (used_memory, used_memory_rss)
  - [ ] Connected clients (peak, average)
  - [ ] Operations per second
  - [ ] Cache hits/misses ratio
  - [ ] Network bandwidth (ingress/egress)
  - [ ] Latency percentiles (p50, p95, p99)
  - [ ] Evicted keys count
  - [ ] Expired keys count

#### 6.2 Sizing Analysis
- [ ] Calculate required memory:
  - [ ] Current used memory
  - [ ] Peak memory usage
  - [ ] Memory fragmentation ratio
  - [ ] Growth projection
- [ ] AMR reserves ~20% memory for operations; factor this in
- [ ] Select appropriate AMR tier:
  - [ ] Memory Optimized (8:1 vCPU ratio)
  - [ ] Balanced (4:1 vCPU ratio)
  - [ ] Compute Optimized (2:1 vCPU ratio)
  - [ ] Flash Optimized (for large datasets)

#### 6.3 Performance Tier Mapping
| ACR Tier | Typical AMR Mapping | Notes |
|----------|---------------------|-------|
| Basic | Balanced (no HA) | Dev/test only |
| Standard | Balanced | General purpose |
| Premium (single shard) | Balanced/Memory Optimized | Based on workload |
| Premium (clustered) | Balanced/Compute Optimized | High throughput |
| Enterprise | Balanced/Compute Optimized | Same Redis Enterprise base |
| Enterprise Flash | Flash Optimized | Large datasets |

#### 6.4 Latency Requirements
- [ ] Document current latency SLAs
- [ ] Note latency-sensitive operations
- [ ] Plan for potential latency changes during migration
- [ ] Consider geo-proximity for optimal performance

---

### 7. High Availability & Disaster Recovery Assessment

#### 7.1 Current HA Configuration

**HA Comparison by Tier:**

| Tier | HA Available | Zone Redundancy | Replicas | Notes |
|------|--------------|-----------------|----------|-------|
| ACR Basic | ❌ No | ❌ | 0 | No SLA |
| ACR Standard | ✅ Always (2 nodes) | Preview | 1 | HA always on, you pay for it |
| ACR Premium | ✅ Always | ✅ Optional | 1-3 | HA always on |
| ACR Enterprise | ✅ Always | ✅ | Built-in | HA always on |
| AMR | ✅ **Optional** | ✅ Default (when HA enabled) | Configurable | **Key advantage: can disable HA for dev/test** |

> **Key Difference:**
> - **ACR Standard/Premium/Enterprise**: HA is **always on** - you pay for replication whether you need it or not
> - **AMR**: HA is **optional** - you can deploy without HA for dev/test environments to save cost
>
> This is an **advantage of AMR** - flexibility to choose:
> - Non-HA for dev/test (cheaper, faster provisioning)
> - HA with zone redundancy for production (default when HA enabled)

- [ ] Document replication setup:
  - [ ] Standard replication (2 nodes)
  - [ ] Multi-replica (Premium: up to 3 replicas)
  - [ ] Zone redundancy enabled?
- [ ] Note current availability SLA
- [ ] **For dev/test environments**: Consider migrating to AMR non-HA for cost savings

#### 7.2 Zone Redundancy Assessment
- [ ] Check if zone redundancy is enabled
- [ ] Verify region supports multiple AZs
- [ ] **Note**: AMR enables zone redundancy by default when HA is enabled
- [ ] Document zone distribution requirements

#### 7.3 Geo-Replication Assessment
| Aspect | ACR Premium | ACR Enterprise | AMR |
|--------|-------------|----------------|-----|
| Type | Passive | Active | Active |
| Read | Secondary read-only | All writable | All writable |
| Failover | Manual unlink required | Automatic | Application-driven |

- [ ] Document current geo-replication setup
- [ ] List linked caches and regions
- [ ] Note RPO/RTO requirements
- [ ] **IMPORTANT**: AMR doesn't support explicit Failover command
- [ ] Plan application-level failover handling

#### 7.4 Backup & Restore Assessment
- [ ] Document data persistence configuration:
  - [ ] RDB persistence (frequency)
  - [ ] AOF persistence (enabled?)
- [ ] Note backup storage location
- [ ] Document retention policy
- [ ] Verify backup file access for migration

#### 7.5 Disaster Recovery Plan
- [ ] Document current DR strategy
- [ ] Note recovery time objectives (RTO)
- [ ] Note recovery point objectives (RPO)
- [ ] Plan for DR in AMR architecture

---

### 8. Data Assessment

#### 8.1 Data Volume Analysis
- [ ] Measure total data size per instance
- [ ] Document key count and size distribution
- [ ] Identify large keys (>1MB)
- [ ] Note data growth rate

#### 8.2 Data Structure Analysis
- [ ] Inventory data types in use:
  - [ ] Strings
  - [ ] Hashes
  - [ ] Lists
  - [ ] Sets
  - [ ] Sorted Sets
  - [ ] Streams
  - [ ] HyperLogLog
  - [ ] Bitmaps
  - [ ] Geospatial
  - [ ] JSON (RedisJSON)
  - [ ] Search indexes (RediSearch)
  - [ ] Time series (RedisTimeSeries)
  - [ ] Bloom filters (RedisBloom)

#### 8.3 TTL and Expiration Analysis
- [ ] Document TTL policies
- [ ] Identify keys with no expiration
- [ ] Note expiration patterns

#### 8.4 Data Migration Strategy
- [ ] Choose migration approach:
  - [ ] **RDB Export/Import**: Point-in-time snapshot (Premium/Enterprise only)
  - [ ] **Dual-write**: Zero data loss, but requires code changes
  - [ ] **RIOT migration tool**: Programmatic migration
  - [ ] **Cache rehydration**: For look-aside caches
- [ ] Document acceptable data loss window
- [ ] Plan migration timing

---

### 9. Monitoring & Logging Assessment

#### 9.1 Current Monitoring Setup
- [ ] Document monitoring tools in use:
  - [ ] Azure Monitor
  - [ ] Application Insights
  - [ ] Third-party tools (Datadog, Grafana, etc.)
- [ ] List configured alerts
- [ ] Document dashboards

#### 9.2 Diagnostic Settings
- [ ] Check diagnostic logs configuration:
  - [ ] Connected client logs
  - [ ] Connection audit logs
- [ ] Note log destinations:
  - [ ] Log Analytics workspace
  - [ ] Storage account
  - [ ] Event Hub
- [ ] **Note**: AMR uses event-based audit logs (vs. poll-based in Premium)

#### 9.3 Metrics Collection
- [ ] Document metrics being collected
- [ ] Note metric namespaces:
  - [ ] ACR: `Microsoft.Cache/redis`
  - [ ] ACR Enterprise: `Microsoft.Cache/redisEnterprise`
  - [ ] AMR: `Microsoft.Cache/redisEnterprise` (new namespace TBD)
- [ ] Plan metric queries update

#### 9.4 Alerting Configuration
- [ ] Export current alert rules
- [ ] Document alert thresholds
- [ ] Note action groups configured
- [ ] Plan alert migration

---

### 10. Compliance & Governance Assessment

#### 10.1 Regulatory Requirements
- [ ] Document compliance requirements:
  - [ ] GDPR
  - [ ] HIPAA
  - [ ] PCI-DSS
  - [ ] SOC 2
  - [ ] Industry-specific regulations
- [ ] Verify AMR meets compliance requirements
- [ ] Note any data residency requirements

#### 10.2 Data Classification
- [ ] Identify data sensitivity levels
- [ ] Document data retention requirements
- [ ] Note encryption requirements

#### 10.3 Azure Policy Assessment
- [ ] List Azure Policies affecting Redis
- [ ] Check for policies that might block AMR deployment
- [ ] Plan policy updates for AMR resources

#### 10.4 RBAC Configuration
- [ ] Document current RBAC assignments:
  - [ ] Contributor access
  - [ ] Reader access
  - [ ] Custom roles
- [ ] Plan RBAC migration for new resources

#### 10.5 Resource Locks
- [ ] Check for resource locks:
  - [ ] CanNotDelete
  - [ ] ReadOnly
- [ ] Plan lock handling during migration

---

### 11. Cost Assessment

#### 11.1 Current Cost Analysis
- [ ] Document current monthly cost per instance
- [ ] Break down costs:
  - [ ] Compute/Memory
  - [ ] Data persistence storage
  - [ ] Network egress
  - [ ] Geo-replication bandwidth
- [ ] Identify reserved capacity purchases

#### 11.2 AMR Cost Estimation
- [ ] Calculate AMR costs for equivalent configuration
- [ ] Compare tier pricing:
  - [ ] Memory Optimized vs. current
  - [ ] Balanced vs. current
  - [ ] Compute Optimized vs. current
- [ ] Factor in:
  - [ ] Zone redundancy (included by default)
  - [ ] No quorum node (Enterprise → AMR = more efficient)
  - [ ] Non-HA option for dev/test

#### 11.3 Cost Optimization Opportunities
- [ ] Evaluate right-sizing opportunities
- [ ] Consider non-HA for dev/test environments
- [ ] Review reserved capacity options for AMR

---

### 12. Operational Readiness

#### 12.1 Team Preparation
- [ ] Identify migration team members
- [ ] Assign roles and responsibilities
- [ ] Plan knowledge transfer sessions
- [ ] Ensure Azure Managed Redis familiarity

#### 12.2 Runbook Updates
- [ ] Update operational runbooks for:
  - [ ] Instance provisioning
  - [ ] Scaling procedures (**Note**: AMR can scale down only to compatible SKUs; geo-replicated caches cannot scale down. Use `az redisenterprise list-skus-for-scaling` to check options)
  - [ ] Failover procedures (different in AMR)
  - [ ] Backup/restore procedures
  - [ ] Troubleshooting guides

#### 12.3 Documentation Updates
- [ ] Plan documentation updates:
  - [ ] Architecture diagrams
  - [ ] Network diagrams
  - [ ] Connection string documentation
  - [ ] Security documentation

#### 12.4 Testing Plan
- [ ] Develop testing strategy:
  - [ ] Functional testing
  - [ ] Performance testing
  - [ ] Failover testing
  - [ ] Security testing
- [ ] Plan test environment setup
- [ ] Define success criteria

#### 12.5 Rollback Preparation
- [ ] Document rollback scenarios
- [ ] Prepare rollback procedures
- [ ] Ensure old instance remains during migration
- [ ] Define rollback triggers

#### 12.6 Infrastructure-as-Code (IaC) Migration

> **IaC templates must be updated** - ACR and AMR use different resource types and providers.

**Resource Type Changes:**

| IaC Tool | ACR Resource | AMR Resource |
|----------|--------------|--------------|
| **Terraform (azurerm)** | `azurerm_redis_cache` | `azurerm_redis_enterprise_cluster` + `azurerm_redis_enterprise_database` |
| **Terraform (azapi)** | `Microsoft.Cache/redis` | `Microsoft.Cache/redisEnterprise` |
| **Bicep/ARM** | `Microsoft.Cache/redis` | `Microsoft.Cache/redisEnterprise` |
| **Private Endpoint** | Zone: `privatelink.redis.cache.windows.net` | Zone: `privatelink.redis.azure.net` |

**Key IaC Migration Tasks:**
- [ ] Update Terraform provider and resource types
- [ ] AMR requires TWO resources: cluster + database (vs single resource for ACR)
- [ ] Update Private DNS zone names in IaC
- [ ] Remove VNet injection configuration (not supported in AMR)
- [ ] Add Private Endpoint configuration instead
- [ ] Update output values (hostname, port, connection string format)
- [ ] **No "shards" parameter in AMR** - sharding is managed internally

**Example Terraform structure change:**
```hcl
# ACR (old)
resource "azurerm_redis_cache" "example" { ... }

# AMR (new) - requires TWO resources
resource "azurerm_redis_enterprise_cluster" "example" { ... }
resource "azurerm_redis_enterprise_database" "example" { ... }
```

---

## Feature Comparison: ACR vs AMR

### Core Features

| Feature | ACR Basic | ACR Standard | ACR Premium | ACR Enterprise | AMR |
|---------|-----------|--------------|-------------|----------------|-----|
| **Memory Size** | 250MB-53GB | 250MB-53GB | 6GB-1.2TB | 1GB-2TB | 0.5GB-4.5TB |
| **Redis Version** | 4.0/6.0 | 4.0/6.0 | 4.0/6.0 | 7.2 | 7.4 |
| **SLA** | ❌ | 99.9% | 99.9% | 99.9-99.99% | 99.9-99.99% |
| **High Availability** | ❌ | ✅ | ✅ | ✅ | ✅ (optional) |
| **Zone Redundancy** | ❌ | Preview | ✅ | ✅ | ✅ (default) |
| **Clustering** | ❌ | ❌ | ✅ (OSS) | ✅ (OSS/Enterprise) | ✅ (OSS/Enterprise/Non-clustered) |
| **Data Persistence** | ❌ | ❌ | ✅ | Preview | ✅ |
| **Import/Export** | ❌ | ❌ | ✅ | ✅ | ✅ |
| **Geo-replication** | ❌ | ❌ | Passive | Active | Active |

### Security Features

| Feature | ACR Basic | ACR Standard | ACR Premium | ACR Enterprise | AMR |
|---------|-----------|--------------|-------------|----------------|-----|
| **Access Keys** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Microsoft Entra ID Auth** | ✅ | ✅ | ✅ | ❌ | ✅ |
| **Data Access Policies (RBAC)** | ✅ | ✅ | ✅ | ❌ | ❌ 🔴 |
| **Disable Access Keys** | ✅ | ✅ | ✅ | ❌ | ❌ 🔴 |
| **Native Redis ACL command** | ❌ Blocked | ❌ Blocked | ❌ Blocked | ❌ Blocked | ❌ Blocked |
| **TLS Encryption** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **TLS + non-TLS same instance** | ✅ | ✅ | ✅ | ✅ | ❌ 🟡 |
| **Private Link** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **VNet Injection** | ❌ | ❌ | ✅ | ❌ | ❌ 🔴 |
| **Firewall Rules (IP)** | ✅ | ✅ | ✅ | ❌ | ❌ 🟡 |

> **Note on Authentication:**
> - **Access Keys**: Simple password-based authentication available on all tiers
> - **Microsoft Entra ID Auth**: Token-based authentication using Azure AD identities. Supported on ACR Basic/Standard/Premium and AMR, but NOT on ACR Enterprise.
> - **Data Access Policies (RBAC)**: Role-based access control via Entra ID with built-in roles (Data Owner/Contributor/Reader) or custom permission strings. **Only supported on ACR Basic/Standard/Premium.**
> - **Native Redis ACL**: The Redis OSS ACL command (`ACL SETUSER`, etc.) is **BLOCKED** on all Azure Redis services.
>
> **Official Documentation:**
> - [Entra ID Authentication](https://learn.microsoft.com/en-us/azure/azure-cache-for-redis/cache-azure-active-directory-for-authentication): "Microsoft Entra authentication isn't supported in the Enterprise tiers of Azure Cache for Redis Enterprise."
> - [Data Access Policies](https://learn.microsoft.com/en-us/azure/azure-cache-for-redis/cache-configure-role-based-access-control): "Configuring data access policies isn't supported on Enterprise and Enterprise Flash tiers."

### Advanced Features

| Feature | ACR Basic | ACR Standard | ACR Premium | ACR Enterprise | AMR |
|---------|-----------|--------------|-------------|----------------|-----|
| **Multiple Databases** | Up to 16 | Up to 16 | Up to 64* | 1 | 1 🔴 |
| **Redis Modules** | ❌ | ❌ | ❌ | ✅ | ✅ |
| **RediSearch** | ❌ | ❌ | ❌ | ✅ | ✅ |
| **RedisJSON** | ❌ | ❌ | ❌ | ✅ | ✅ |
| **RedisBloom** | ❌ | ❌ | ❌ | ✅ | ✅ |
| **RedisTimeSeries** | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Keyspace Notifications** | ✅ | ✅ | ✅ | ✅ | ❌ 🟡 |
| **Scheduled Updates** | ✅ | ✅ | ✅ | ❌ | Preview |
| **Manual Reboot** | ✅ | ✅ | ✅ | ❌ | ❌ 🟡 |
| **Flush Operation** | Via commands | Via commands | Via commands | Via commands | ✅ Management API |

> *Premium with clustering enabled only supports database 0

---

## Breaking Changes & Blockers

### 🔴 Critical Blockers (Must Resolve Before Migration)

#### 1. Multiple Database Usage (Non-Clustered ACR Only)
- **Issue**: AMR only supports database 0 (clustered by default)
- **ACR Support**: 
  - Basic/Standard: Up to 16-64 databases (non-clustered)
  - Premium (non-clustered): Up to 64 databases
  - Premium (clustered): Only database 0 ✅ No change needed
  - Enterprise/Enterprise Flash: Only database 0 ✅ No change needed
- **Impact**: Applications using `SELECT` command on non-clustered ACR will fail
- **Resolution**:
  ```
  Option A: Use key prefixes instead of databases
    Before: SELECT 1; SET mykey value
    After:  SET db1:mykey value
  
  Option B: Use separate AMR instances per logical database
  
  Option C: Redesign data model
  ```

#### 2. VNet Injection Dependency
- **Issue**: AMR doesn't support VNet injection
- **ACR Support**: Premium tier supports VNet injection
- **Impact**: Cannot directly inject AMR into existing VNet
- **Resolution**: 
  - Migrate to Private Link
  - Update NSG rules for Private Endpoint subnet
  - Update routing if needed

#### 3. Microsoft Entra ID Data Access Policies (RBAC)
- **Issue**: AMR supports Entra ID authentication but does NOT support Data Access Policies (RBAC)
- **ACR Support**: 
  - **ACR Basic/Standard/Premium**: Full support for Entra ID + Data Access Policies (Data Owner/Contributor/Reader)
  - **ACR Enterprise/Enterprise Flash**: ❌ No Entra ID support at all
- **What this means**:
  - AMR: You can authenticate via Entra ID, but ALL authenticated users have full access
  - ACR Enterprise: Already using access keys only, so no change needed for AMR
- **Impact**: Cannot use Entra ID for granular Redis permissions in AMR
- **Resolution**:
  - Use access keys for Redis authentication if you need simplicity
  - Use Entra ID auth in AMR with application-level access control
  - Use network segmentation (Private Link + NSGs) for isolation
  - Consider multiple AMR instances for strong isolation

> **Official Documentation:**
> - [Entra ID Auth](https://learn.microsoft.com/en-us/azure/azure-cache-for-redis/cache-azure-active-directory-for-authentication)
> - [Data Access Policies](https://learn.microsoft.com/en-us/azure/azure-cache-for-redis/cache-configure-role-based-access-control)

### 🟡 High Impact Changes (Require Attention)

#### 4. TLS Required (No Non-TLS Option)
- **Issue**: AMR is TLS-only; non-TLS connections are NOT supported
- **ACR Support**: Both modes simultaneously (port 6379 non-TLS and 6380 TLS)
- **Impact**: All clients MUST use TLS
- **Resolution**: 
  - Migrate all clients to TLS before cutover
  - Update connection strings to use TLS
  - This is a **BLOCKER** if any clients cannot support TLS

#### 5. Port Number Changes
| Connection Type | ACR | AMR |
|-----------------|-----|-----|
| TLS | 6380 | 10000 |
| Non-TLS | 6379 | **Not supported** |
| Cluster nodes | 13XXX/15XXX | 85XX |

#### 6. Scaling Limitations
- **Issue**: AMR has specific rules for scaling down
- **ACR Support**: Scale up/down and in/out (Premium clustered)
- **AMR Rules**:
  - ✅ Scale down allowed if memory usage < target size AND target SKU is compatible
  - ❌ Geo-replicated caches cannot scale down to smaller memory or shard count
  - Use `az redisenterprise list-skus-for-scaling` to check available scale-down options
- **Resolution**:
  - Right-size carefully during initial deployment
  - Use metrics to verify memory usage before scaling down
  - For geo-replicated caches, plan capacity carefully as scale-down is blocked

#### 7. DNS Suffix Changes
- **ACR**: `<name>.redis.cache.windows.net`
- **AMR**: `<name>.<region>.redis.azure.net`
- **Private DNS Zones**:
  - ACR: `privatelink.redis.cache.windows.net`
  - AMR: `privatelink.redis.azure.net`

#### 8. Firewall Rules
- **Issue**: AMR doesn't support IP-based firewall rules
- **Resolution**: Use Private Link + NSG + Azure Firewall

#### 9. Keyspace Notifications
- **Issue**: ❌ Not available in AMR (verified)
- **ACR Support**:
  - **Basic**: ❌ Not available
  - **Standard/Premium**: ✅ Configurable via `notify-keyspace-events` in Advanced Settings
  - **Enterprise**: ❌ Not available
- **What they do**: Allow clients to subscribe to Pub/Sub channels to receive events when keys are modified, expired, or evicted
- **Common use cases**: Cache invalidation triggers, session expiration notifications, TTL-based workflows
- **Impact**: Applications relying on key event notifications will need redesign
- **Resolution**: 
  - Use Pub/Sub with explicit application notifications
  - Implement application-level change tracking
  - Consider event sourcing patterns

#### 10. Manual Reboot Not Available
- **Issue**: Cannot manually reboot AMR nodes
- **ACR**: Reboot option available for testing resilience
- **Resolution**: AMR manages node operations automatically

### 🟢 Improvements in AMR

1. **Better Performance**: Multi-threaded Redis Enterprise architecture
2. **Redis 7.4**: Latest Redis version with new features
3. **Active Geo-replication**: All regions writable (vs. passive in Premium)
4. **Zone Redundancy by Default**: When HA enabled
5. **Persistence on All Tiers**: Not limited to Premium
6. **No Quorum Node**: More efficient resource utilization
7. **Non-HA Option**: Cost savings for dev/test
8. **Redis Modules**: RediSearch, RedisJSON, etc. on all tiers

---

## Migration Strategies

### Strategy 1: Blue-Green Migration (Recommended)

```
┌──────────────┐    ┌──────────────┐
│   ACR        │    │   AMR        │
│  (Primary)   │    │  (Target)    │
└──────┬───────┘    └──────┬───────┘
       │                   │
       ▼                   ▼
┌──────────────────────────────────┐
│         Application              │
│   (Dual-write during migration)  │
└──────────────────────────────────┘
```

**Steps**:
1. Create AMR instance with equivalent configuration
2. Implement dual-write in application
3. Migrate data (if needed)
4. Validate data consistency
5. Switch reads to AMR
6. Remove writes to ACR
7. Decommission ACR

**Pros**: Zero downtime, rollback possible
**Cons**: Requires code changes, runs two caches temporarily

### Strategy 2: RDB Export/Import (Premium/Enterprise Only)

**Steps**:
1. Create AMR instance
2. Export RDB from ACR (Premium/Enterprise)
3. Import RDB into AMR
4. Switch application connection strings
5. Validate and decommission ACR

**Pros**: Simple, no code changes
**Cons**: Point-in-time snapshot, brief downtime for switchover

### Strategy 3: RIOT Migration Tool

**Steps**:
1. Create AMR instance
2. Set up RIOT on a VM in same region
3. Run RIOT replication
4. Switch application connection strings
5. Validate and decommission ACR

**Pros**: Online migration, minimal downtime
**Cons**: Requires additional infrastructure

### Strategy 4: Cache Rehydration (Look-aside Caches)

**Steps**:
1. Create AMR instance
2. Update application connection strings
3. Allow cache to warm up from backend
4. Decommission ACR

**Pros**: Simplest approach
**Cons**: Temporary performance impact during warming

---

## Migration Steps

### Phase 1: Pre-Migration (2-4 weeks before)

1. [ ] Complete all pre-migration checklists
2. [ ] Resolve all blockers identified
3. [ ] Create AMR instances in test environment
4. [ ] Test application connectivity
5. [ ] Performance test AMR configuration
6. [ ] Document all configuration changes needed
7. [ ] Prepare connection string updates
8. [ ] Update monitoring/alerting for AMR

### Phase 2: Preparation (1 week before)

1. [ ] Final review of migration plan
2. [ ] Communicate migration window to stakeholders
3. [ ] Create AMR production instance
4. [ ] Configure networking (Private Link, DNS)
5. [ ] Apply security configuration
6. [ ] Set up monitoring and diagnostics
7. [ ] Prepare rollback procedures

### Phase 3: Migration (Migration Window)

#### Option A: Blue-Green with Dual-Write
1. [ ] Enable dual-write to both caches
2. [ ] Monitor for errors
3. [ ] Validate data in AMR
4. [ ] Switch reads to AMR
5. [ ] Monitor performance
6. [ ] Disable writes to ACR

#### Option B: RDB Export/Import
1. [ ] Export RDB from ACR
2. [ ] Import RDB into AMR
3. [ ] Verify data integrity
4. [ ] Update connection strings
5. [ ] Deploy application changes
6. [ ] Validate connectivity

### Phase 4: Post-Migration (1-2 weeks after)

1. [ ] Monitor application performance
2. [ ] Verify all functionality working
3. [ ] Update documentation
4. [ ] Train operations team
5. [ ] Delete ACR instance (after validation period)
6. [ ] Clean up old resources

---

## Post-Migration Validation

### Functional Validation
- [ ] All applications connecting successfully
- [ ] Read operations working
- [ ] Write operations working
- [ ] Pub/Sub working (if used)
- [ ] Lua scripts executing correctly
- [ ] Multi-key operations working (if used)

### Performance Validation
- [ ] Latency within acceptable range
- [ ] Throughput meeting requirements
- [ ] No connection errors
- [ ] Memory utilization healthy
- [ ] CPU utilization healthy

### Security Validation
- [ ] TLS connections verified
- [ ] Private endpoint connectivity confirmed
- [ ] Access keys rotated
- [ ] RBAC assignments verified
- [ ] Network security verified

### Monitoring Validation
- [ ] Metrics flowing to Azure Monitor
- [ ] Alerts configured and tested
- [ ] Logs being collected
- [ ] Dashboards updated

---

## Rollback Plan

### Rollback Triggers
- Critical application functionality broken
- Performance degradation beyond acceptable thresholds
- Data integrity issues discovered
- Security concerns identified

### Rollback Procedure

1. **Immediate Actions**
   - [ ] Revert connection strings to ACR
   - [ ] Deploy application changes to point back to ACR
   - [ ] Notify stakeholders

2. **Data Synchronization** (if needed)
   - [ ] Evaluate data delta during AMR operation
   - [ ] Export data from AMR if needed
   - [ ] Import critical data back to ACR

3. **Post-Rollback**
   - [ ] Root cause analysis
   - [ ] Document lessons learned
   - [ ] Plan remediation
   - [ ] Reschedule migration

### Rollback Timeline
- Keep ACR instance running for minimum 2 weeks post-migration
- Don't delete ACR until confident AMR is stable
- Consider keeping read-replica ACR for safety net

---

## Appendix A: Connection String Formats

### ACR Connection String
```
<name>.redis.cache.windows.net:6380,password=<key>,ssl=True,abortConnect=False
```

### AMR Connection String
```
<name>.<region>.redis.azure.net:10000,password=<key>,ssl=True,abortConnect=False
```

---

## Appendix B: Quick Reference

### Key Changes Summary

| Aspect | ACR | AMR |
|--------|-----|-----|
| DNS Suffix | `.redis.cache.windows.net` | `.<region>.redis.azure.net` |
| TLS Port | 6380 | 10000 |
| Non-TLS Port | 6379 | 10000 |
| Redis Version | 4.0/6.0/7.2 | 7.4 |
| Databases | 1-64 (non-clustered only) | 1 only |
| Clustering | Optional (Premium) | Default |
| VNet Injection | Yes (Premium) | No |
| Firewall Rules | Yes | No |
| Entra ID RBAC | Yes | No |
| Persistence | Premium/Enterprise | All tiers |
| Zone Redundancy | Premium/Enterprise | Default with HA |

---

## Appendix C: Resources

- [Official Migration Guide - Basic/Standard/Premium](https://learn.microsoft.com/en-us/azure/redis/migrate/migrate-basic-standard-premium-overview)
- [Official Migration Guide - Enterprise](https://learn.microsoft.com/en-us/azure/redis/migrate/migrate-redis-enterprise-overview)
- [AMR Architecture](https://learn.microsoft.com/en-us/azure/redis/architecture)
- [AMR Quickstart](https://learn.microsoft.com/en-us/azure/redis/quickstart-create-managed-redis)
- [RIOT Migration Tool](https://techcommunity.microsoft.com/blog/azure-managed-redis/data-migration-with-riot-x-for-azure-managed-redis/4404672)
- [Redis Migration Agent Skill](https://github.com/AzureManagedRedis/amr-migration-skill)

---

*Document maintained by: Infrastructure Team*  
*Last Review: April 2026*
