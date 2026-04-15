# ACR to AMR Migration Workshop

> **Workshop Duration**: 2.5 hours  
> **Audience**: Platform Engineers, DevOps, Architects  
> **Prerequisites**: Azure subscription, basic Redis knowledge

---

## Workshop Agenda

| Time | Duration | Section | Content |
|------|----------|---------|---------|
| 13:00 | 10 min | **Introduction** | Welcome, objectives, housekeeping |
| 13:10 | 30 min | **Redis Use Cases** | Redis - The Real-Time data platform |
| 13:40 | 10 min | ☕ **Break** | |
| 13:50 | 15 min | **The Burning Platform** | Retirement timeline, what is AMR |
| 14:05 | 45 min | **Critical Differences** | 13 breaking changes deep dive |
| 14:50 | 10 min | ☕ **Break** | |
| 15:00 | 20 min | **Migration & Next Steps** | Strategies, checklist, action items |
| 15:20 | 10 min | **Q&A** | Open discussion |

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

# PART 2: REDIS - THE REAL-TIME DATA PLATFORM (30 min)

---

## Slide 2: What is Redis?

### Redis = The Real-Time Data Platform

> "Redis is an in-memory data store that provides **sub-millisecond latency** for real-time applications"

| Capability | What It Means |
|------------|---------------|
| **Speed** | <1ms latency, 1M+ ops/sec |
| **Versatility** | 10+ data structures, not just key-value |
| **Real-Time** | Instant reads/writes, pub/sub, streaming |
| **Simplicity** | Easy APIs, no query language needed |

---

## Slide 3: The Real-Time Data Challenge

### Why Traditional Databases Aren't Enough

```
User Action → API → Database → Response
                      ↓
                   10-100ms ❌
```

### Modern User Expectations
- Gaming: **Instant** leaderboard updates
- E-commerce: **Real-time** inventory
- Social: **Live** notifications
- Finance: **Immediate** fraud detection

**Latency = Lost Revenue + Bad UX**

---

## Slide 4: Redis as the Speed Layer

### The Real-Time Architecture

```
┌──────────┐     ┌─────────────────────┐     ┌──────────────┐
│   App    │────▶│   Redis (Speed)     │────▶│   Database   │
│          │◀────│   <1ms response     │◀────│   (Storage)  │
└──────────┘     └─────────────────────┘     └──────────────┘
                 │ Real-time layer      │   │ Source of truth │
                 │ • Caching            │   │ • Durability     │
                 │ • Sessions           │   │ • Complex queries│
                 │ • Leaderboards       │   │ • Analytics      │
                 │ • Rate limiting      │
```

---

## Slide 5: Real-Time Use Case: Caching

### Reduce Database Load by 80-95%

```python
def get_product(product_id):
    # Try cache first
    cached = redis.get(f"product:{product_id}")
    if cached:
        return json.loads(cached)  # <1ms ✅
    
    # Cache miss → DB
    product = db.query(product_id)  # 10-100ms
    redis.setex(f"product:{product_id}", 3600, json.dumps(product))
    return product
```

**Impact**: Faster response + lower DB costs

---

## Slide 6: Real-Time Use Case: Session Store

### Stateless Apps, Fast Sessions

```python
# Login: Store session
redis.setex(f"session:{token}", 3600, json.dumps(user_data))

# Every request: Validate session
user = json.loads(redis.get(f"session:{token}"))  # <1ms
```

**Why Redis for Sessions?**
- Scale app servers horizontally
- Automatic expiration (TTL)
- Shared across all instances

---

## Slide 7: Real-Time Use Case: Leaderboards

### Instant Rankings with Sorted Sets

```python
# Update score (real-time)
redis.zadd("game:leaderboard", {"player42": 15000})

# Get top 10 (instant)
top_10 = redis.zrevrange("game:leaderboard", 0, 9, withscores=True)

# Get player rank (instant)
rank = redis.zrevrank("game:leaderboard", "player42")
```

**O(log N)** - Scales to millions of players

---

## Slide 8: Real-Time Use Case: Rate Limiting

### Protect APIs in Real-Time

```python
def check_rate_limit(user_id, limit=100, window=60):
    key = f"rate:{user_id}:{int(time.time()) // window}"
    count = redis.incr(key)
    redis.expire(key, window)
    return count <= limit
```

**Use Cases**:
- API throttling (prevent abuse)
- Login protection (brute force)
- Feature flags (gradual rollout)

---

## Slide 9: Real-Time Use Case: Pub/Sub & Streams

### Event-Driven Architecture

```python
# Publisher (real-time events)
redis.publish("orders", json.dumps({"order_id": 123, "status": "shipped"}))

# Subscriber (instant notification)
for message in pubsub.listen():
    notify_customer(message)
```

**Redis Streams** (persistent):
- Event sourcing
- Activity feeds
- IoT data ingestion

---

## Slide 10: Redis Data Structures

| Structure | Real-Time Use Case |
|-----------|-------------------|
| **String** | Caching, counters, feature flags |
| **Hash** | User profiles, product catalog |
| **List** | Job queues, activity feeds |
| **Set** | Tags, unique visitors, fraud detection |
| **Sorted Set** | Leaderboards, time-based data |
| **Stream** | Event logs, message queues |
| **JSON** | Complex documents (Redis module) |
| **Search** | Full-text search (Redis module) |
| **TimeSeries** | Metrics, IoT (Redis module) |

---

## Slide 11: Redis on Azure Today

### Two Products → One Future

| Product | Status | Based On |
|---------|--------|----------|
| **Azure Cache for Redis (ACR)** | ⚠️ Retiring | Community Redis |
| **Azure Managed Redis (AMR)** | ✅ Future | Redis Enterprise |

### AMR = Real-Time Data Platform on Azure
- **Multi-threaded**: Full CPU utilization
- **Redis 7.4**: Latest features
- **Active Geo-Rep**: Real-time globally
- **Modules**: Search, JSON, TimeSeries built-in

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
