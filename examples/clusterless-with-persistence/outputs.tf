output "cluster_id" {
  description = "The ID of the Redis cluster"
  value       = module.redis_clusterless.cluster_id
}

output "cluster_name" {
  description = "The name of the Redis cluster"
  value       = module.redis_clusterless.cluster_name
}

output "hostname" {
  description = "The hostname of the Redis cluster"
  value       = module.redis_clusterless.hostname
}

output "port" {
  description = "The port of the Redis database"
  value       = module.redis_clusterless.port
}

output "database_id" {
  description = "The ID of the Redis database"
  value       = module.redis_clusterless.database_id
}

output "database_name" {
  description = "The name of the Redis database"
  value       = module.redis_clusterless.database_name
}

output "connection_string_format" {
  description = "Format for Redis connection string (replace <ACCESS_KEY> with actual key)"
  value       = "rediss://:<ACCESS_KEY>@${module.redis_clusterless.hostname}:${module.redis_clusterless.port}"
}

output "redis_cli_command_format" {
  description = "Format for redis-cli command (replace <primary_key> with actual key)"
  value       = "redis-cli -h ${module.redis_clusterless.hostname} -p ${module.redis_clusterless.port} --tls -a '<primary_key>' --no-auth-warning"
}

output "persistence_info" {
  description = "Persistence configuration information"
  value = {
    rdb_enabled = true
    aof_enabled = true
    info        = "Both RDB (snapshots) and AOF (write log) persistence are enabled for maximum durability"
  }
}

output "clustering_info" {
  description = "Clustering configuration information"
  value = {
    policy = "EnterpriseCluster"
    info   = "Clusterless deployment - single shard, all keys on one node"
  }
}
