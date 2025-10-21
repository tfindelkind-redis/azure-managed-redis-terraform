# Redis with Modules Example

This example demonstrates deploying Azure Managed Redis with multiple Redis Enterprise modules enabled.

## 🆕 New SKU Options Available

With the latest API update, you can now use enhanced SKU options for better performance:

- **Flash Optimized**: `FlashOptimized_A250` - `FlashOptimized_A4500` (NEW! - Optimized for high throughput)
- **Memory Optimized**: `MemoryOptimized_M50` - `MemoryOptimized_M2000` (Expanded range)
- **Balanced**: `Balanced_B10` - `Balanced_B1000` (More size options)

## Enabled Modules

When `enable_all_modules = true`:
- **RedisJSON**: Store, update and query JSON values
- **RediSearch**: Full-text search with secondary indexing  
- **RedisBloom**: Probabilistic data structures (Bloom filters, Cuckoo filters)
- **RedisTimeSeries**: Time series data structures and operations

## Module Capabilities

### RedisJSON
```bash
# Store JSON documents
JSON.SET user:1 $ '{"name":"John","age":30,"city":"New York"}'

# Query JSON values  
JSON.GET user:1 $.name
```

### RediSearch  
```bash
# Create index
FT.CREATE users_idx ON JSON PREFIX 1 user: SCHEMA $.name AS name TEXT $.age AS age NUMERIC

# Search users
FT.SEARCH users_idx "@age:[25 35]"
```

### RedisBloom
```bash  
# Create and add to Bloom filter
BF.RESERVE bf_users 0.01 1000
BF.ADD bf_users john@example.com
BF.EXISTS bf_users john@example.com
```

### RedisTimeSeries
```bash
# Create time series
TS.CREATE temperature:sensor1 RETENTION 3600 LABELS sensor_id 1 type temperature

# Add sample
TS.ADD temperature:sensor1 * 23.5

# Query range
TS.RANGE temperature:sensor1 - +
```

## Usage

1. Deploy with all modules:
```bash
terraform init
terraform apply -var="enable_all_modules=true"
```

2. Deploy with basic modules only:
```bash  
terraform apply -var="enable_all_modules=false"
```

3. Test module functionality:
```bash
# Get connection details
HOSTNAME=$(terraform output -raw hostname)
PORT=$(terraform output -raw port)
PRIMARY_KEY=$(terraform output -raw primary_key)

# Test RedisJSON
redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning JSON.SET test $ '{"hello":"world"}'
redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning JSON.GET test

# Test RediSearch (if enabled)  
redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning FT.CREATE idx ON JSON PREFIX 1 doc: SCHEMA $.title AS title TEXT
```

## Requirements

- **SKU**: Balanced_B1 or higher (modules require more memory)
- **High Availability**: Enabled for production workloads
- **TLS**: Version 1.2 for secure connections

## Cost Considerations

Redis modules increase resource usage:
- More memory required per module
- Higher SKU needed for optimal performance  
- Consider module usage patterns for cost optimization

## Next Steps

- See [high-availability example](../high-availability/) for production deployment
- Review module documentation for advanced features
- Monitor performance with Azure Monitor integration
