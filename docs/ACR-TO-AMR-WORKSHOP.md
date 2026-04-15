# ACR to AMR Migration Workshop

> **Workshop Duration**: 2.5 hours  
> **Audience**: Platform Engineers, DevOps, Architects  
> **Prerequisites**: Azure subscription, basic Redis knowledge

---

## Workshop Agenda

| Time | Duration | Section | Content |
|------|----------|---------|---------|
| 0:00 | 10 min | **Introduction** | Welcome, objectives, housekeeping |
| 0:10 | 30 min | **Redis Use Cases** | Why Redis? Patterns & anti-patterns |
| 0:40 | 10 min | ☕ **Break** | |
| 0:50 | 15 min | **The Burning Platform** | Retirement timeline, what is AMR |
| 1:05 | 45 min | **Critical Differences** | 13 breaking changes deep dive |
| 1:50 | 10 min | ☕ **Break** | |
| 2:00 | 20 min | **Migration & Next Steps** | Strategies, checklist, action items |
| 2:20 | 10 min | **Q&A** | Open discussion |

---

# PART 1: INTRODUCTION

---

## Slide 1: Welcome & Objectives

### Workshop Goals

By the end of this session, you will:

1. ✅ Understand **why** ACR is being retired
2. ✅ Know the **13 critical differences** between ACR and AMR
3. ✅ Identify **blockers** in your current environment
4. ✅ Have a **migration action plan**

### Ground Rules
- Questions welcome anytime
- Slides & resources shared after
- Focus on YOUR environment

---

# PART 2: REDIS USE CASES (30 min)

---

## Slide 2: Why Redis?

### The Speed Problem

| Storage Type | Latency |
|--------------|---------|
| SSD Database | 1-10 ms |
| Network call | 10-100 ms |
| **Redis (in-memory)** | **<1 ms** |

### Redis = In-Memory Data Store
- Sub-millisecond response times
- 1M+ operations/second
- Rich data structures (not just key-value)

---

## Slide 3: Core Redis Use Cases

### 1️⃣ Caching (Most Common)

```
┌─────────┐    ┌─────────┐    ┌──────────┐
│   App   │───▶│  Redis  │───▶│ Database │
└─────────┘    └─────────┘    └──────────┘
                  Cache          Source
                  <1ms           10-100ms
```

**Pattern**: Cache-Aside
- Check Redis first
- If miss → query DB → store in Redis
- Reduces DB load by 80-95%

---

## Slide 4: Core Redis Use Cases (cont.)

### 2️⃣ Session Store

```python
# Store session (with TTL)
redis.setex(f"session:{session_id}", 3600, user_data)

# Retrieve session
user_data = redis.get(f"session:{session_id}")
```

**Benefits**:
- Stateless app servers (scale horizontally)
- Fast session lookup
- Automatic expiration

---

## Slide 5: Core Redis Use Cases (cont.)

### 3️⃣ Real-Time Leaderboards

```python
# Add score
redis.zadd("leaderboard", {"player1": 1500, "player2": 2300})

# Get top 10
redis.zrevrange("leaderboard", 0, 9, withscores=True)
```

**Why Redis?**
- Sorted Sets = O(log N) operations
- Real-time updates
- No complex SQL queries

---

## Slide 6: Core Redis Use Cases (cont.)

### 4️⃣ Rate Limiting

```python
def is_rate_limited(user_id, limit=100, window=60):
    key = f"rate:{user_id}"
    current = redis.incr(key)
    if current == 1:
        redis.expire(key, window)
    return current > limit
```

**Use Cases**:
- API throttling
- Login attempt limits
- DDoS protection

---

## Slide 7: Core Redis Use Cases (cont.)

### 5️⃣ Pub/Sub & Messaging

```python
# Publisher
redis.publish("notifications", json.dumps(event))

# Subscriber
pubsub = redis.pubsub()
pubsub.subscribe("notifications")
for message in pubsub.listen():
    process(message)
```

**Use Cases**:
- Real-time notifications
- Chat applications
- Event broadcasting

---

## Slide 8: Core Redis Use Cases (cont.)

### 6️⃣ Distributed Locks

```python
# Acquire lock
lock = redis.set("lock:resource", "owner1", nx=True, ex=30)

# Release lock (with Lua for atomicity)
if redis.get("lock:resource") == "owner1":
    redis.delete("lock:resource")
```

**Use Cases**:
- Prevent duplicate processing
- Coordinate microservices
- Leader election

---

## Slide 9: Redis Data Structures

| Structure | Use Case | Example |
|-----------|----------|---------|
| **String** | Cache, counters | Page views, session data |
| **Hash** | Objects | User profiles, configs |
| **List** | Queues | Job queues, activity feeds |
| **Set** | Unique items | Tags, online users |
| **Sorted Set** | Rankings | Leaderboards, time series |
| **Stream** | Event logs | Activity streams, IoT data |

---

## Slide 10: Redis Anti-Patterns ⚠️

| Anti-Pattern | Problem | Better Approach |
|--------------|---------|-----------------|
| **Large values (>100KB)** | Network latency, memory | Compress or chunk |
| **KEYS * in production** | Blocks Redis | Use SCAN |
| **No TTL on cache** | Memory leak | Always set expiration |
| **Single huge key** | Hot spot | Shard across keys |
| **Using as primary DB** | No durability guarantee | Use for cache/speed layer |

---

## Slide 11: Redis on Azure - Current State

### Two Products (Soon One)

| Product | Status | Based On |
|---------|--------|----------|
| **Azure Cache for Redis (ACR)** | ⚠️ Retiring | Community Redis |
| **Azure Managed Redis (AMR)** | ✅ Future | Redis Enterprise |

### Why the Change?
- ACR = Single-threaded, limited features
- AMR = Multi-threaded, enterprise features, better performance

---

# ☕ BREAK (10 min)

---

# PART 3: THE BURNING PLATFORM

---

## Slide 12: ACR Retirement Timeline 🔥

| Tier | Retirement Date | Time Left* |
|------|-----------------|------------|
| Basic | **Sept 30, 2028** | ~29 months |
| Standard | **Sept 30, 2028** | ~29 months |
| Premium | **Sept 30, 2028** | ~29 months |
| Enterprise | **March 31, 2027** | ⚠️ ~11 months |
| Enterprise Flash | **March 31, 2027** | ⚠️ ~11 months |

*As of April 2026

> 🚨 **Enterprise tier customers: You're first!**

---

## Slide 13: What is Azure Managed Redis?

### AMR = Redis Enterprise on Azure

| Feature | ACR | AMR |
|---------|-----|-----|
| Architecture | Single-threaded | **Multi-threaded** |
| Redis Version | 4.0 / 6.0 | **7.4** |
| Performance | 1 vCPU utilized | **All vCPUs utilized** |
| Geo-Replication | Passive (read-only) | **Active (all writable)** |
| HA | Always on | **Optional** (cost savings) |
| Modules | Enterprise only | **All tiers** |

---

## Slide 14: AMR Tier Overview

| Tier | Memory:vCPU | Best For |
|------|-------------|----------|
| **Memory Optimized (M)** | 8:1 | Dev/Test, memory-heavy |
| **Balanced (B)** | 4:1 | Standard workloads |
| **Compute Optimized (X)** | 2:1 | High-throughput |
| **Flash Optimized (A)** | NVMe + RAM | Large datasets |

---

# PART 4: CRITICAL DIFFERENCES (45 min)

---

## Slide 15: The 13 Things That Will Break

| # | Change | Impact | Quick Check |
|---|--------|--------|-------------|
| 1 | Entra ID RBAC | 🔴 | Using Data Access Policies? |
| 2 | Multiple DBs | 🔴 | Using SELECT command? |
| 3 | Clustering | 🟡 | Client library support? |
| 4 | VNet Injection | 🟡 | Premium with VNet? |
| 5 | DNS/Port | 🟡 | Hardcoded connections? |
| 6 | TLS Mode | 🟡 | Any non-TLS clients? |
| 7 | Scaling | 🟡 | Need to scale down? |
| 8 | Region | 🟡 | AMR in your region? |
| 9 | IP Firewall | 🟡 | Using IP rules? |
| 10 | IaC/Terraform | 🟡 | Infrastructure as Code? |
| 11 | Private DNS | 🟡 | Using Private Link? |
| 12 | Keyspace Notifications | 🟡 | Using key events? |
| 13 | HA Optional | 🟢 | Cost savings opportunity! |

---

## Slide 16: 🔴 #1 Entra ID RBAC

### What Changes

| | ACR Basic/Std/Premium | ACR Enterprise | AMR |
|-|----------------------|----------------|-----|
| Entra ID Auth | ✅ | ❌ | ✅ |
| Data Access Policies | ✅ | ❌ | ❌ |

### Impact
- Lose granular permissions (Owner/Contributor/Reader)
- All authenticated users get full access

### Action Required
- [ ] Audit current RBAC usage
- [ ] Plan application-level access control
- [ ] Consider separate instances for isolation

---

## Slide 17: 🔴 #2 Multiple Databases

### What Changes

| | ACR (non-clustered) | AMR |
|-|---------------------|-----|
| Databases | Up to 64 | **Only db0** |
| SELECT command | ✅ | ❌ Fails |

### Check Your Environment
```bash
redis-cli INFO keyspace
# db0:keys=1000  ← OK
# db1:keys=500   ← BLOCKER!
```

### Migration Options
1. Key prefixes: `SELECT 1; SET key` → `SET db1:key`
2. Separate AMR instances per database
3. Redesign data model

---

## Slide 18: 🟡 #3 Clustering

### What Changes
- AMR is **always clustered internally**
- Default: **Enterprise Cluster Policy** (looks non-clustered to clients)

### Cluster Policies

| Policy | Behavior |
|--------|----------|
| **Enterprise** (default) | Single endpoint, no CROSSSLOT errors ✅ |
| **OSS** | Multi-endpoint, higher throughput |
| **Non-Clustered** | ≤25GB only, no sharding |

### Action Required
- [ ] Verify client library supports clustering
- [ ] Test multi-key commands (MGET, MSET, PIPELINE)

---

## Slide 19: 🟡 #4 VNet Injection

### What Changes

| | ACR Premium | AMR |
|-|-------------|-----|
| VNet Injection | ✅ | ❌ |
| Private Link | ✅ | ✅ Required |

### Impact
- Cannot deploy Redis inside your subnet
- Must use Private Endpoint instead

### Action Required
- [ ] Identify Premium instances with VNet injection
- [ ] Plan Private Endpoint deployment
- [ ] Update NSG rules

---

## Slide 20: 🟡 #5 DNS/Port Changes

### Connection String Changes

```diff
- myredis.redis.cache.windows.net:6380
+ myredis.westus2.redis.azure.net:10000
```

### Port Mapping

| Type | ACR | AMR |
|------|-----|-----|
| TLS | 6380 | **10000** |
| Non-TLS | 6379 | ❌ Not supported |

### Action Required
- [ ] Update all connection strings
- [ ] Remove hardcoded ports
- [ ] Update monitoring endpoints

---

## Slide 21: 🟡 #6 TLS Required

### What Changes

| | ACR | AMR |
|-|-----|-----|
| TLS | Optional | **Required** |
| Non-TLS | ✅ Port 6379 | ❌ |

### ⚠️ BLOCKER if any client cannot use TLS

### Action Required
- [ ] Audit all clients for TLS capability
- [ ] Check legacy apps, scripts, tools
- [ ] Migrate ALL to TLS before cutover

---

## Slide 22: 🟡 #7 Scaling Limitations

### What Changes

| Scaling | ACR | AMR |
|---------|-----|-----|
| Up | ✅ | ✅ |
| Down | ✅ | ⚠️ Limited |

### AMR Rules
- ✅ Scale down if memory < target AND SKU compatible
- ❌ Geo-replicated caches cannot scale down

```bash
# Check what you can scale to
az redisenterprise list-skus-for-scaling \
  --cluster-name myamr --resource-group myrg
```

### Action Required
- [ ] **Right-size carefully** - can't easily reduce later

---

## Slide 23: 🟡 #8 Region Availability

### What Changes
- AMR not available in all ACR regions (yet)

### Action Required
- [ ] Check AMR availability in your region
- [ ] Plan region migration if needed

```bash
az provider show --namespace Microsoft.Cache \
  --query "resourceTypes[?resourceType=='redisEnterprise'].locations"
```

---

## Slide 24: 🟡 #9 IP Firewall Rules

### What Changes

| | ACR | AMR |
|-|-----|-----|
| IP Firewall | ✅ | ❌ |
| Private Link | ✅ | ✅ Required |

### Action Required
- [ ] Replace IP rules with Private Link + NSG
- [ ] Update network security architecture

---

## Slide 25: 🟡 #10 IaC/Terraform Changes

### Resource Type Changes

| | ACR | AMR |
|-|-----|-----|
| Cluster | `azurerm_redis_cache` | `azurerm_redis_enterprise_cluster` |
| Database | (included) | `azurerm_redis_enterprise_database` |

### AMR requires TWO resources (cluster + database)

### Action Required
- [ ] Update Terraform/Bicep/ARM templates
- [ ] Plan IaC migration alongside cache migration

---

## Slide 26: 🟡 #11 Private DNS Zones

### What Changes

```diff
- privatelink.redis.cache.windows.net
+ privatelink.redis.azure.net
```

### Action Required
- [ ] Create new Private DNS Zone
- [ ] Link to VNets
- [ ] Update Private Endpoint DNS config

---

## Slide 27: 🟡 #12 Keyspace Notifications

### What Changes

| | ACR Std/Premium | AMR |
|-|-----------------|-----|
| Keyspace Notifications | ✅ | ❌ |

### What They Do
- Subscribe to key events (SET, DEL, EXPIRE)
- Trigger on TTL expiration

### Action Required (if using)
- [ ] Redesign with explicit Pub/Sub
- [ ] Implement application-level tracking

---

## Slide 28: 🟢 #13 HA Optional (ADVANTAGE!)

### What Changes

| | ACR Std/Premium/Enterprise | AMR |
|-|---------------------------|-----|
| HA | Always on (pay for it) | **Optional** |

### 💰 Cost Savings Opportunity
- Disable HA for dev/test
- Lower cost, same functionality for non-prod

### Action Required
- [ ] Identify dev/test instances
- [ ] Plan to disable HA for non-production

---

# ☕ BREAK (10 min)

---

# PART 5: MIGRATION & NEXT STEPS (20 min)

---

## Slide 29: Migration Strategy Summary

| Strategy | Downtime | Complexity | Best For |
|----------|----------|------------|----------|
| **Export/Import** | Minutes-Hours | Low | Dev/Test, small data |
| **Dual-Write** | Zero | High | Production, critical |
| **RIOT Tool** | Near-zero | Medium | Large datasets |

### Recommendation
- **Dev/Test**: Export/Import (simplest)
- **Production**: Dual-Write or RIOT (zero downtime)

---

## Slide 30: Pre-Migration Checklist Summary

### 🔴 Critical Blockers (Check First!)
- [ ] Multiple databases in use? → Redesign
- [ ] Entra ID RBAC dependencies? → Plan alternative

### 🟡 High Impact (Must Address)
- [ ] Non-TLS clients? → Migrate to TLS
- [ ] VNet Injection? → Switch to Private Link
- [ ] Hardcoded ports/hostnames? → Update configs
- [ ] IP Firewall rules? → Replace with NSG

### 🟢 Opportunities
- [ ] Dev/Test HA? → Disable for cost savings

---

## Slide 31: Your Action Items

### This Week
1. **Inventory**: List all ACR instances
   ```bash
   az redis list -o table
   az redisenterprise list -o table
   ```

2. **Identify blockers**: Check for multiple DBs, non-TLS
   ```bash
   redis-cli INFO keyspace
   ```

3. **Check region**: Verify AMR availability

### This Month
4. **Size**: Analyze memory, connections, ops/sec
5. **Plan**: Choose migration strategy per instance
6. **IaC**: Update Terraform/Bicep templates

---

## Slide 32: Timeline Recommendation

### Enterprise Tier (Deadline: March 2027)
| Phase | When | What |
|-------|------|------|
| Assess | **Now** | Inventory, blockers |
| Plan | Q2 2026 | Design, IaC |
| Migrate | Q3-Q4 2026 | Execute |
| Buffer | Q1 2027 | Contingency |

### Basic/Standard/Premium (Deadline: Sept 2028)
| Phase | When | What |
|-------|------|------|
| Assess | Q3 2026 | Inventory, blockers |
| Plan | Q4 2026 - Q1 2027 | Design, IaC |
| Migrate | 2027 - mid 2028 | Execute |
| Buffer | Q3 2028 | Contingency |

---

## Slide 33: Resources

### Documentation
- [AMR Overview](https://learn.microsoft.com/en-us/azure/redis/overview)
- [Migration Guide - Basic/Std/Premium](https://learn.microsoft.com/en-us/azure/redis/migrate/migrate-basic-standard-premium-overview)
- [Migration Guide - Enterprise](https://learn.microsoft.com/en-us/azure/redis/migrate/migrate-redis-enterprise-overview)

### Tools
- [RIOT Migration Tool](https://redis.github.io/riot/)
- [Redis Insight](https://redis.com/redis-enterprise/redis-insight/)

### This Workshop
- Full migration plan: `docs/ACR-TO-AMR-MIGRATION-PLAN.md`
- Terraform examples: `examples/` folder

---

# PART 6: Q&A (10 min)

---

## Slide 34: Common Questions

**Q: Enterprise tier deadline is soon - what if we can't make it?**
A: Start NOW. Contact Azure support if blocked.

**Q: Can we keep using access keys?**
A: Yes, access keys work in AMR.

**Q: Do we need new client libraries?**
A: Usually no, but verify TLS + clustering support.

**Q: What about costs?**
A: Similar, but save on dev/test with optional HA.

**Q: Active-Active geo-replication?**
A: Supported on all AMR tiers (except Flash).

---

## Appendix A: Quick Reference - SKU Mapping

| ACR SKU | AMR SKU |
|---------|---------|
| Basic C0-C3 | Balanced B0-B1 |
| Standard C0-C6 | Balanced B1-B5 |
| Premium P1-P5 | Balanced B5-B20 |
| Enterprise E10-E100 | Balanced B10-B100 |
| Enterprise Flash | Flash A-series |

---

## Appendix B: Quick Reference - Ports

| Connection | ACR | AMR |
|------------|-----|-----|
| TLS | 6380 | 10000 |
| Non-TLS | 6379 | ❌ |
| OSS Cluster | 13XXX | 85XX |

---

## Appendix C: CLI Commands

```bash
# List ACR
az redis list -o table

# List Enterprise ACR  
az redisenterprise list -o table

# Create AMR
az redisenterprise create \
  --name myamr --resource-group myrg \
  --location westus2 --sku Balanced_B10

# Create database
az redisenterprise database create \
  --cluster-name myamr --resource-group myrg \
  --client-protocol Encrypted \
  --clustering-policy EnterpriseCluster

# Check scaling options
az redisenterprise list-skus-for-scaling \
  --cluster-name myamr --resource-group myrg
```

---

*End of Workshop*
