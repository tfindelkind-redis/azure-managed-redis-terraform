# ACR to AMR Migration Workshop

<!-- 
PRESENTER: Welcome everyone to the ACR to AMR Migration Workshop. 
My name is [Your Name] and I'll be guiding you through the migration from Azure Cache for Redis to Azure Managed Redis.

This is a 2.5 hour workshop with two breaks. We'll cover:
- What Redis is and why it matters for real-time applications
- The retirement timeline and what's changing
- 13 critical differences you MUST know before migrating
- Action items you can take immediately after this session

Feel free to ask questions at any time. Let's get started!
-->

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

<!-- 
PRESENTER: Here's our agenda for today. We start with Redis fundamentals - even if you know Redis, this sets the stage for why the migration matters.

After the first break, we dive into the "burning platform" - the retirement timeline. Enterprise tier customers, pay close attention - your deadline is FIRST.

The bulk of the workshop - 45 minutes - covers the 13 critical differences. These are the things that WILL break your applications if you don't address them.

We end with concrete action items you can start this week.
-->

---

# PART 1: INTRODUCTION

---

## Welcome & Objectives

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

<!-- 
PRESENTER: Four concrete outcomes today. 

First, you'll understand WHY Microsoft is retiring ACR - it's not just a name change, it's a fundamental architecture shift.

Second, you'll know the 13 things that are DIFFERENT between ACR and AMR. Some are breaking changes, some are improvements.

Third, by the end, you should be able to identify blockers in YOUR environment. We'll give you the commands to check.

Fourth, you'll leave with specific action items - not just "go migrate" but actual CLI commands and checklists.

Questions are welcome anytime. We'll send slides after. Think about YOUR environment as we go through this.
-->

---

# PART 2: REDIS - THE REAL-TIME DATA PLATFORM

---

## What is Redis?

### Redis = The Real-Time Data Platform

> "Redis is an in-memory data store that provides **sub-millisecond latency** for real-time applications"

| Capability | What It Means |
|------------|---------------|
| **Speed** | <1ms latency, 1M+ ops/sec |
| **Versatility** | 10+ data structures, not just key-value |
| **Real-Time** | Instant reads/writes, pub/sub, streaming |
| **Simplicity** | Easy APIs, no query language needed |

<!-- 
PRESENTER: Let's start with what Redis actually IS.

Redis is NOT just a cache - that's a common misconception. Redis is a real-time data platform.

The key word here is REAL-TIME. Sub-millisecond latency. That's 1000x faster than a typical database query.

Redis can handle over 1 million operations per second on a single node. That's why gaming companies, financial services, and e-commerce platforms depend on it.

It's also versatile - 10+ data structures. Strings, hashes, lists, sets, sorted sets, streams, and more. Each optimized for different use cases.

And it's simple - no query language to learn. GET, SET, ZADD - straightforward commands.
-->

---

## The Real-Time Data Challenge

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

<!-- 
PRESENTER: Here's the problem Redis solves.

Traditional databases are great for durability and complex queries. But they're SLOW - 10 to 100 milliseconds per query.

Modern users don't wait. Amazon found that every 100ms of latency costs 1% in sales. Google found that 500ms delay reduces traffic by 20%.

Gaming - players expect instant leaderboard updates when they score.
E-commerce - customers want real-time inventory, not "sorry, out of stock" at checkout.
Social media - notifications must be instant.
Finance - fraud detection must happen before the transaction completes.

This is why Redis exists - to be the speed layer in your architecture.
-->

---

## Redis as the Speed Layer

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

<!-- 
PRESENTER: Here's the architecture pattern.

Redis sits BETWEEN your application and your database. It's the speed layer.

Your database remains the source of truth - durable, ACID-compliant, good for analytics.

Redis handles the real-time operations - caching, sessions, leaderboards, rate limiting.

Your app talks to Redis first. If the data is there - under 1ms response. If not, fall back to the database, then cache in Redis.

This pattern reduces database load by 80-95% while dramatically improving user experience.
-->

---

## Real-Time Use Case: Caching

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

<!-- 
PRESENTER: The most common use case - caching.

Look at this code pattern - it's simple. Try Redis first. If hit, return immediately - under 1ms.

If miss, query the database, then store in Redis with a TTL - 3600 seconds here, one hour.

The impact is huge. We've seen customers reduce database load by 80-95%. That means faster responses AND lower database costs.

Every read-heavy application should be doing this. If you're hitting your database on every request, you're wasting money and hurting user experience.
-->

---

## Real-Time Use Case: Session Store

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

<!-- 
PRESENTER: Second use case - session storage.

If sessions are stored in your app server's memory, you can't scale horizontally. Sticky sessions are a pain.

With Redis, sessions are shared across all app instances. User logs in on server 1, their next request can go to server 2 - doesn't matter.

TTL handles expiration automatically. Set it to 1 hour, Redis deletes it after 1 hour. No cleanup jobs needed.

And it's FAST - validating a session on every request adds less than 1ms of latency.
-->

---

## Real-Time Use Case: Leaderboards

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

<!-- 
PRESENTER: Leaderboards are a perfect Redis use case.

Sorted Sets are the secret weapon here. ZADD adds or updates a score. ZREVRANGE gets the top N. ZREVRANK gets a player's position.

All of these are O(log N) operations. That means even with millions of players, these operations complete in microseconds.

Try doing this in SQL - you'd need ORDER BY, LIMIT, maybe a COUNT subquery. That's slow and doesn't scale.

Gaming companies use this pattern extensively. But it applies to any ranking - top sellers, trending content, high scores.
-->

---

## Real-Time Use Case: Rate Limiting

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

<!-- 
PRESENTER: Rate limiting - critical for API protection.

This pattern uses Redis INCR for atomic counting. Each request increments a counter, key expires after the window.

100 requests per minute? Track with a key that includes the current minute. When minute changes, new key, counter resets.

Use cases: API throttling to prevent abuse, login protection against brute force, even gradual feature rollouts.

Without this, a single bad actor can overwhelm your API. With Redis, you can check and block in under 1ms.
-->

---

## Real-Time Use Case: Pub/Sub & Streams

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

<!-- 
PRESENTER: Pub/Sub for real-time messaging.

Publisher sends a message to a channel. All subscribers receive it instantly - typically under 1ms.

Great for real-time notifications, chat applications, live updates.

Redis Streams are similar but persistent - messages are stored and can be replayed. Perfect for event sourcing, activity feeds, IoT data ingestion.

If you're using a separate message broker just for simple pub/sub, consider consolidating into Redis.
-->

---

## Redis Data Structures

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

<!-- 
PRESENTER: Here's the full toolkit of Redis data structures.

Strings for simple caching and counters.
Hashes for objects like user profiles.
Lists for queues.
Sets for unique items and tags.
Sorted Sets for rankings.
Streams for event logs.

Plus Redis modules - JSON for complex documents, Search for full-text search, TimeSeries for metrics.

AMR includes these modules on ALL tiers. ACR only had them on Enterprise.

Each structure is optimized for specific access patterns. Choose the right one and you get incredible performance.
-->

---

## Redis on Azure Today

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

<!-- 
PRESENTER: Now let's talk about Redis on Azure.

Currently there are two products: Azure Cache for Redis (ACR) and Azure Managed Redis (AMR).

ACR is based on community Redis - single-threaded, limited features.
AMR is based on Redis Enterprise - multi-threaded, full feature set.

ACR is being RETIRED. AMR is the future.

AMR is not just a rename - it's a fundamental upgrade:
- Multi-threaded means better CPU utilization
- Redis 7.4 has the latest features
- Active geo-replication means all regions can write
- Modules are included on all tiers

This is why Microsoft is making the change. But it means you need to migrate.
-->

---

# ☕ BREAK (10 min)

<!-- 
PRESENTER: Let's take a 10-minute break. 

When we come back, we'll dive into the retirement timeline and what's changing.

If you have any quick questions, feel free to ask now. Otherwise, see you in 10 minutes.
-->

---

# PART 3: THE BURNING PLATFORM

---

## ACR Retirement Timeline 🔥

| Tier | Retirement Date | Time Left* |
|------|-----------------|------------|
| Basic | **Sept 30, 2028** | ~29 months |
| Standard | **Sept 30, 2028** | ~29 months |
| Premium | **Sept 30, 2028** | ~29 months |
| Enterprise | **March 31, 2027** | ⚠️ ~11 months |
| Enterprise Flash | **March 31, 2027** | ⚠️ ~11 months |

*As of April 2026

> 🚨 **Enterprise tier customers: You're first!**

<!-- 
PRESENTER: Here's the burning platform - the retirement timeline.

Look at these dates carefully:
- Basic, Standard, Premium: September 30, 2028 - about 29 months from now
- Enterprise and Enterprise Flash: March 31, 2027 - only 11 months!

If you're on Enterprise tier, this is URGENT. You need to start NOW.

Basic/Standard/Premium customers have more time, but don't wait. These migrations take planning and testing.

Note: These dates are firm. After retirement, ACR instances will stop working. There's no extension.
-->

---

## What is Azure Managed Redis?

### AMR = Redis Enterprise on Azure

| Feature | ACR | AMR |
|---------|-----|-----|
| Architecture | Single-threaded | **Multi-threaded** |
| Redis Version | 4.0 / 6.0 | **7.4** |
| Performance | 1 vCPU utilized | **All vCPUs utilized** |
| Geo-Replication | Passive (read-only) | **Active (all writable)** |
| HA | Always on | **Optional** (cost savings) |
| Modules | Enterprise only | **All tiers** |

<!-- 
PRESENTER: What is AMR? It's Redis Enterprise running as a managed service on Azure.

Key differences:
- MULTI-THREADED: ACR was single-threaded, so adding more vCPUs didn't help linearly. AMR uses all vCPUs.
- REDIS 7.4: Latest version with new features and performance improvements.
- ACTIVE GEO-REPLICATION: ACR had passive geo-rep where secondaries were read-only. AMR has active - all regions can write.
- OPTIONAL HA: ACR forced you to pay for HA even in dev/test. AMR lets you disable it for cost savings.
- MODULES ON ALL TIERS: Search, JSON, TimeSeries were Enterprise-only in ACR. AMR has them on all tiers.

This is genuinely better technology. But it comes with breaking changes.
-->

---

## AMR Tier Overview

| Tier | Memory:vCPU | Best For |
|------|-------------|----------|
| **Memory Optimized (M)** | 8:1 | Dev/Test, memory-heavy |
| **Balanced (B)** | 4:1 | Standard workloads |
| **Compute Optimized (X)** | 2:1 | High-throughput |
| **Flash Optimized (A)** | NVMe + RAM | Large datasets |

<!-- 
PRESENTER: AMR has four tier families.

Memory Optimized - 8GB per vCPU - good for dev/test or memory-heavy workloads
Balanced - 4GB per vCPU - the default choice for most workloads
Compute Optimized - 2GB per vCPU - when you need high throughput
Flash Optimized - uses NVMe plus RAM - for very large datasets cost-effectively

The naming changed from ACR's C0-C6, P1-P5 to B5, B10, X10, etc.

We'll cover SKU mapping in the appendix, but the key point is: you need to right-size carefully because scaling DOWN is limited in AMR.
-->

---

# PART 4: CRITICAL DIFFERENCES

---

## The 13 Things That Will Break

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

<!-- 
PRESENTER: Here are the 13 things that are different between ACR and AMR.

Red items are CRITICAL BLOCKERS - they will break your application if you don't address them first.
Yellow items are HIGH IMPACT - you must address them but they're not blockers.
Green items are ADVANTAGES - take advantage of them!

As I go through each one, think about YOUR environment. Does this apply to you?

We'll spend the next 45 minutes going through each one in detail.
-->

---

## 🔴 #1 Entra ID RBAC

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

<!-- 
PRESENTER: First critical blocker - Entra ID RBAC.

ACR Basic/Standard/Premium supported Data Access Policies - you could give users Owner, Contributor, or Reader permissions at the data level.

AMR does NOT support this. All authenticated users get full access to all data.

If you're using Data Access Policies to restrict who can read vs write, you need a new approach:
- Implement access control in your application layer
- Use separate AMR instances per team or application
- Rely on network segmentation

This is a fundamental design change. Audit your current RBAC usage NOW.
-->

---

## 🔴 #2 Multiple Databases

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

<!-- 
PRESENTER: Second critical blocker - multiple databases.

Non-clustered ACR supported up to 64 databases - db0 through db63. You switch with the SELECT command.

AMR only supports db0. The SELECT command will FAIL.

Why? AMR is always clustered internally, and clustered Redis only supports database 0.

Check your environment right now - run redis-cli INFO keyspace. If you see db1, db2, etc., you have a blocker.

Migration options:
1. Use key prefixes instead of databases: "db1:mykey" instead of SELECT 1; SET mykey
2. Separate AMR instances per database
3. Redesign your data model

This requires code changes. Start identifying this NOW.
-->

---

## 🟡 #3 Clustering

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

<!-- 
PRESENTER: Clustering - this is high impact but manageable.

AMR is ALWAYS clustered internally - data is sharded across nodes.

BUT - the default Enterprise Cluster Policy makes it transparent. You get a single endpoint, no CROSSSLOT errors.

For most applications with modern client libraries, this just works. But you should verify:
- Does your client library support clustering? Most do.
- Test multi-key commands like MGET, MSET, pipelines.

If you need higher throughput, you can use OSS Cluster Policy with multiple endpoints.

If you absolutely cannot use clustering and have less than 25GB, there's a Non-Clustered option.
-->

---

## 🟡 #4 VNet Injection

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

<!-- 
PRESENTER: VNet Injection is NOT supported in AMR.

With ACR Premium, you could deploy Redis directly INTO your subnet using VNet injection.

With AMR, you MUST use Private Link instead. Redis runs in Microsoft's network, you connect via Private Endpoint.

Practically speaking:
- You need to create Private Endpoints for each AMR instance
- Update your NSG rules to allow traffic to the Private Endpoint subnet
- DNS changes - we'll cover that separately

If you're using VNet injection today, plan for Private Endpoint migration.
-->

---

## 🟡 #5 DNS/Port Changes

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

<!-- 
PRESENTER: Connection strings change completely.

The hostname format changes - note the region is now embedded in the hostname.

More importantly, the PORT changes:
- ACR used 6380 for TLS
- AMR uses 10000 for TLS
- NON-TLS (6379) is NOT supported in AMR

If you have hardcoded connection strings or ports anywhere - config files, environment variables, code - you need to update them.

Don't forget monitoring and alerting endpoints too.
-->

---

## 🟡 #6 TLS Required

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

<!-- 
PRESENTER: TLS is REQUIRED in AMR. Non-TLS is not supported.

This is a potential BLOCKER. If you have ANY client that cannot use TLS - a legacy application, an old script, a tool - it will stop working.

Audit ALL clients:
- Your applications
- Admin scripts
- Monitoring agents
- CI/CD pipelines
- Any tools that connect to Redis

Every single one must support TLS. If not, migrate them to TLS BEFORE you migrate to AMR.
-->

---

## 🟡 #7 Scaling Limitations

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

<!-- 
PRESENTER: Scaling DOWN is limited in AMR.

With ACR, you could scale up and down freely.

With AMR:
- Scaling UP always works
- Scaling DOWN requires: memory usage below target, AND target SKU must be compatible
- Geo-replicated caches CANNOT scale down

There's a CLI command to check what SKUs you can scale to.

The key takeaway: RIGHT-SIZE CAREFULLY when you migrate. Pick an appropriate size, not oversized. You can't easily reduce later.

This is different from ACR where you could start big and scale down.
-->

---

## 🟡 #8 Region Availability

### What Changes
- AMR not available in all ACR regions (yet)

### Action Required
- [ ] Check AMR availability in your region
- [ ] Plan region migration if needed

```bash
az provider show --namespace Microsoft.Cache \
  --query "resourceTypes[?resourceType=='redisEnterprise'].locations"
```

<!-- 
PRESENTER: Region availability - AMR is not in all regions yet.

Before you plan migration, check if AMR is available in YOUR region.

Run this CLI command to see the list of supported regions.

If your region isn't supported:
- Wait - Microsoft is expanding to more regions
- Move to a nearby supported region
- Keep ACR until your region is available

Consider latency impact if you need to change regions.
-->

---

## 🟡 #9 IP Firewall Rules

### What Changes

| | ACR | AMR |
|-|-----|-----|
| IP Firewall | ✅ | ❌ |
| Private Link | ✅ | ✅ Required |

### Action Required
- [ ] Replace IP rules with Private Link + NSG
- [ ] Update network security architecture

<!-- 
PRESENTER: IP Firewall rules are NOT supported in AMR.

With ACR, you could whitelist specific public IPs.

With AMR, you must use Private Link for network isolation. Combine with NSG for granular control.

This is actually more secure - Private Link means traffic never goes over the public internet.

But it requires architectural changes if you're relying on IP whitelisting today.
-->

---

## 🟡 #10 IaC/Terraform Changes

### Resource Type Changes

| | ACR | AMR |
|-|-----|-----|
| Cluster | `azurerm_redis_cache` | `azurerm_redis_enterprise_cluster` |
| Database | (included) | `azurerm_redis_enterprise_database` |

### AMR requires TWO resources (cluster + database)

### Action Required
- [ ] Update Terraform/Bicep/ARM templates
- [ ] Plan IaC migration alongside cache migration

<!-- 
PRESENTER: Infrastructure as Code changes.

The Terraform resource types are completely different:
- ACR: azurerm_redis_cache
- AMR: azurerm_redis_enterprise_cluster PLUS azurerm_redis_enterprise_database

AMR requires TWO resources - a cluster and a database. This is different from ACR where everything was one resource.

If you use Terraform, Bicep, or ARM templates, you need to update them.

Plan to migrate your IaC alongside the cache migration. Don't forget to update outputs and any references.
-->

---

## 🟡 #11 Private DNS Zones

### What Changes

```diff
- privatelink.redis.cache.windows.net
+ privatelink.redis.azure.net
```

### Action Required
- [ ] Create new Private DNS Zone
- [ ] Link to VNets
- [ ] Update Private Endpoint DNS config

<!-- 
PRESENTER: Private DNS zones change.

If you're using Private Link with ACR, your DNS zone is privatelink.redis.cache.windows.net.

For AMR, it's privatelink.redis.azure.net.

You need to:
1. Create the new Private DNS Zone
2. Link it to your VNets
3. Configure your Private Endpoint to use this zone

Keep the old zone until you've fully decommissioned ACR.
-->

---

## 🟡 #12 Keyspace Notifications

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

<!-- 
PRESENTER: Keyspace Notifications are NOT available in AMR.

If you don't know what these are, you probably don't use them.

Keyspace notifications let you subscribe to Redis key events - when a key is set, deleted, or expires.

Common use cases:
- Cache invalidation triggers
- Session expiration handling
- TTL-based workflows

If you use these, you need to redesign:
- Use explicit Pub/Sub instead
- Application publishes when it makes changes
- Track TTL expiration in application code

This requires code changes.
-->

---

## 🟢 #13 HA Optional (ADVANTAGE!)

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

<!-- 
PRESENTER: Finally, some good news! HA is optional in AMR.

With ACR, you paid for high availability even in dev/test environments.

With AMR, you can DISABLE HA. Lower cost, same functionality for non-production.

This is a cost savings opportunity. Identify your dev/test instances and plan to deploy them without HA.

Production should still have HA enabled for reliability.
-->

---

# ☕ BREAK (10 min)

<!-- 
PRESENTER: Let's take another 10-minute break.

When we come back, we'll cover migration strategies and your action items.

Think about what we've covered - which of the 13 items apply to YOUR environment?
-->

---

# PART 5: MIGRATION & NEXT STEPS

---

## Migration Strategy Summary

| Strategy | Downtime | Complexity | Best For |
|----------|----------|------------|----------|
| **Export/Import** | Minutes-Hours | Low | Dev/Test, small data |
| **Dual-Write** | Zero | High | Production, critical |
| **RIOT Tool** | Near-zero | Medium | Large datasets |

### Recommendation
- **Dev/Test**: Export/Import (simplest)
- **Production**: Dual-Write or RIOT (zero downtime)

<!-- 
PRESENTER: Three migration strategies.

Export/Import: Simple but requires downtime. Export RDB from ACR, import to AMR, switch over. Good for dev/test or small datasets.

Dual-Write: Zero downtime but complex. Your app writes to both ACR and AMR during migration. Once data is synced, switch reads to AMR, then remove ACR writes.

RIOT Tool: Near-zero downtime, medium complexity. Redis' migration tool does live replication. Good for large datasets.

For dev/test: use Export/Import - it's simplest.
For production: use Dual-Write or RIOT - you need zero or near-zero downtime.
-->

---

## Pre-Migration Checklist Summary

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

<!-- 
PRESENTER: Here's your pre-migration checklist summary.

START with critical blockers:
- Multiple databases - check redis-cli INFO keyspace
- Entra ID RBAC - audit your Data Access Policies

Then address high impact items:
- Non-TLS clients - audit and migrate
- VNet Injection - plan Private Endpoint
- Hardcoded connections - find and update
- IP Firewall - redesign with Private Link + NSG

And take advantage of opportunities:
- Disable HA for dev/test to save costs
-->

---

## Your Action Items

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

<!-- 
PRESENTER: Concrete action items.

THIS WEEK:
1. Inventory - run these CLI commands to list all your ACR instances
2. Check for blockers - multiple databases, non-TLS clients
3. Verify AMR is available in your regions

THIS MONTH:
4. Analyze sizing - memory, connections, operations per second
5. Choose migration strategy for each instance
6. Start updating your IaC templates

Don't wait. Start this week.
-->

---

## Timeline Recommendation

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

<!-- 
PRESENTER: Recommended timeline.

Enterprise tier - deadline March 2027:
- Assess NOW - you have 11 months
- Plan in Q2 2026
- Migrate Q3-Q4 2026
- Q1 2027 buffer for contingency

Basic/Standard/Premium - deadline September 2028:
- More time, but don't wait until the last minute
- Start assessment Q3 2026
- Plan over Q4 2026 and Q1 2027
- Migrate throughout 2027 and first half of 2028
- Buffer in Q3 2028

Build in contingency time. Migrations always take longer than expected.
-->

---

## Resources

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

<!-- 
PRESENTER: Resources for your migration.

Documentation links - Microsoft's official guides for both migration paths.

Tools - RIOT for migration, Redis Insight for visualization and debugging.

From this workshop:
- The full migration plan document has much more detail
- Terraform examples in the examples folder

These slides will be shared after the session.
-->

---

# PART 6: Q&A

---

## Common Questions

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

<!-- 
PRESENTER: Common questions we get.

Enterprise deadline - START NOW. If you're truly blocked, contact Azure support, but there's no extension.

Access keys - YES, they still work in AMR. No change there.

Client libraries - Usually no changes needed. Just verify TLS support and clustering support.

Costs - Similar to ACR. Save money on dev/test by disabling HA.

Active-Active geo-rep - Available on all tiers except Flash. This is an upgrade from ACR where it was Enterprise-only.

Any other questions?
-->

---

## Appendix A: Quick Reference - SKU Mapping

| ACR SKU | AMR SKU |
|---------|---------|
| Basic C0-C3 | Balanced B0-B1 |
| Standard C0-C6 | Balanced B1-B5 |
| Premium P1-P5 | Balanced B5-B20 |
| Enterprise E10-E100 | Balanced B10-B100 |
| Enterprise Flash | Flash A-series |

<!-- 
PRESENTER: SKU mapping reference. Use this when planning your migration.
-->

---

## Appendix B: Quick Reference - Ports

| Connection | ACR | AMR |
|------------|-----|-----|
| TLS | 6380 | 10000 |
| Non-TLS | 6379 | ❌ |
| OSS Cluster | 13XXX | 85XX |

<!-- 
PRESENTER: Port reference. Note: non-TLS is not supported in AMR.
-->

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

<!-- 
PRESENTER: CLI quick reference. Use these commands to get started with your inventory and AMR deployment.
-->

---

# Thank You!

### Questions?

<!-- 
PRESENTER: Thank you for attending!

Key takeaways:
1. ACR is retiring - Enterprise first in March 2027, others in September 2028
2. 13 critical differences - start with blockers (multiple DBs, RBAC)
3. Start your inventory THIS WEEK

Slides and resources will be shared.

Any final questions?
-->
