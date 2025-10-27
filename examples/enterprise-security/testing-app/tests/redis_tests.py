"""
Redis Test Suite
Comprehensive tests for Redis connectivity and operations
"""
import time
import logging
from datetime import datetime
from utils.redis_client import redis_client

logger = logging.getLogger(__name__)


class RedisTestSuite:
    """Test suite for Redis operations"""
    
    def __init__(self):
        self.client = redis_client.get_client()
    
    def test_connection(self):
        """Test basic connection to Redis"""
        start_time = time.time()
        try:
            if self.client is None:
                return {
                    "status": "fail",
                    "error": "No Redis client available",
                    "duration_ms": 0
                }
            
            result = self.client.ping()
            duration_ms = (time.time() - start_time) * 1000
            
            return {
                "status": "pass" if result else "fail",
                "message": "PONG" if result else "No response",
                "duration_ms": round(duration_ms, 2)
            }
        except Exception as e:
            duration_ms = (time.time() - start_time) * 1000
            logger.error(f"Connection test failed: {e}")
            return {
                "status": "fail",
                "error": str(e),
                "duration_ms": round(duration_ms, 2)
            }
    
    def test_set_operation(self, key="test:key", value="test_value"):
        """Test SET operation"""
        start_time = time.time()
        try:
            if self.client is None:
                return {"status": "fail", "error": "No Redis client available"}
            
            result = self.client.set(key, value)
            duration_ms = (time.time() - start_time) * 1000
            
            return {
                "status": "pass" if result else "fail",
                "key": key,
                "value": value,
                "duration_ms": round(duration_ms, 2)
            }
        except Exception as e:
            duration_ms = (time.time() - start_time) * 1000
            logger.error(f"SET test failed: {e}")
            return {
                "status": "fail",
                "error": str(e),
                "duration_ms": round(duration_ms, 2)
            }
    
    def test_get_operation(self, key="test:key"):
        """Test GET operation"""
        start_time = time.time()
        try:
            if self.client is None:
                return {"status": "fail", "error": "No Redis client available"}
            
            value = self.client.get(key)
            duration_ms = (time.time() - start_time) * 1000
            
            return {
                "status": "pass" if value is not None else "fail",
                "key": key,
                "value": value,
                "duration_ms": round(duration_ms, 2)
            }
        except Exception as e:
            duration_ms = (time.time() - start_time) * 1000
            logger.error(f"GET test failed: {e}")
            return {
                "status": "fail",
                "error": str(e),
                "duration_ms": round(duration_ms, 2)
            }
    
    def test_delete_operation(self, key="test:key"):
        """Test DELETE operation"""
        start_time = time.time()
        try:
            if self.client is None:
                return {"status": "fail", "error": "No Redis client available"}
            
            result = self.client.delete(key)
            duration_ms = (time.time() - start_time) * 1000
            
            return {
                "status": "pass",
                "key": key,
                "deleted": result > 0,
                "duration_ms": round(duration_ms, 2)
            }
        except Exception as e:
            duration_ms = (time.time() - start_time) * 1000
            logger.error(f"DELETE test failed: {e}")
            return {
                "status": "fail",
                "error": str(e),
                "duration_ms": round(duration_ms, 2)
            }
    
    def test_incr_operation(self, key="test:counter"):
        """Test INCR operation"""
        start_time = time.time()
        try:
            if self.client is None:
                return {"status": "fail", "error": "No Redis client available"}
            
            # Clean up first
            self.client.delete(key)
            
            # Test increment
            value = self.client.incr(key)
            duration_ms = (time.time() - start_time) * 1000
            
            # Clean up
            self.client.delete(key)
            
            return {
                "status": "pass" if value == 1 else "fail",
                "key": key,
                "value": value,
                "duration_ms": round(duration_ms, 2)
            }
        except Exception as e:
            duration_ms = (time.time() - start_time) * 1000
            logger.error(f"INCR test failed: {e}")
            return {
                "status": "fail",
                "error": str(e),
                "duration_ms": round(duration_ms, 2)
            }
    
    def test_ttl_operation(self, key="test:ttl", ttl=5):
        """Test TTL (expiration) operation"""
        start_time = time.time()
        try:
            if self.client is None:
                return {"status": "fail", "error": "No Redis client available"}
            
            # Set key with TTL
            self.client.setex(key, ttl, "test_value")
            
            # Get TTL
            remaining_ttl = self.client.ttl(key)
            duration_ms = (time.time() - start_time) * 1000
            
            # Clean up
            self.client.delete(key)
            
            return {
                "status": "pass" if remaining_ttl > 0 else "fail",
                "key": key,
                "ttl_set": ttl,
                "ttl_remaining": remaining_ttl,
                "duration_ms": round(duration_ms, 2)
            }
        except Exception as e:
            duration_ms = (time.time() - start_time) * 1000
            logger.error(f"TTL test failed: {e}")
            return {
                "status": "fail",
                "error": str(e),
                "duration_ms": round(duration_ms, 2)
            }
    
    def test_performance(self, iterations=100):
        """Test performance with multiple operations"""
        start_time = time.time()
        try:
            if self.client is None:
                return {"status": "fail", "error": "No Redis client available"}
            
            operations = {
                "set": 0,
                "get": 0,
                "delete": 0
            }
            
            key_prefix = f"test:perf:{int(time.time())}"
            
            # SET operations
            for i in range(iterations):
                self.client.set(f"{key_prefix}:{i}", f"value_{i}")
                operations["set"] += 1
            
            # GET operations
            for i in range(iterations):
                self.client.get(f"{key_prefix}:{i}")
                operations["get"] += 1
            
            # DELETE operations
            for i in range(iterations):
                self.client.delete(f"{key_prefix}:{i}")
                operations["delete"] += 1
            
            duration_ms = (time.time() - start_time) * 1000
            ops_per_second = (iterations * 3) / (duration_ms / 1000)
            
            return {
                "status": "pass",
                "iterations": iterations,
                "operations": operations,
                "total_operations": iterations * 3,
                "duration_ms": round(duration_ms, 2),
                "ops_per_second": round(ops_per_second, 2),
                "avg_latency_ms": round(duration_ms / (iterations * 3), 2)
            }
        except Exception as e:
            duration_ms = (time.time() - start_time) * 1000
            logger.error(f"Performance test failed: {e}")
            return {
                "status": "fail",
                "error": str(e),
                "duration_ms": round(duration_ms, 2)
            }
    
    def get_redis_info(self):
        """Get Redis server information"""
        try:
            if self.client is None:
                return {"status": "fail", "error": "No Redis client available"}
            
            info = self.client.info()
            
            return {
                "status": "pass",
                "redis_version": info.get("redis_version", "unknown"),
                "uptime_seconds": info.get("uptime_in_seconds", 0),
                "connected_clients": info.get("connected_clients", 0),
                "used_memory_human": info.get("used_memory_human", "0"),
                "total_commands_processed": info.get("total_commands_processed", 0),
                "keyspace": info.get("db0", {})
            }
        except Exception as e:
            logger.error(f"Failed to get Redis info: {e}")
            return {
                "status": "fail",
                "error": str(e)
            }
    
    def run_full_test_suite(self):
        """Run complete test suite"""
        logger.info("Running full Redis test suite")
        start_time = time.time()
        
        test_key = f"test:full:{int(time.time())}"
        
        results = {
            "timestamp": datetime.utcnow().isoformat(),
            "status": "running",
            "tests": {}
        }
        
        # Run all tests
        results["tests"]["connection"] = self.test_connection()
        results["tests"]["set"] = self.test_set_operation(test_key, "test_value")
        results["tests"]["get"] = self.test_get_operation(test_key)
        results["tests"]["incr"] = self.test_incr_operation(f"{test_key}:counter")
        results["tests"]["ttl"] = self.test_ttl_operation(f"{test_key}:ttl")
        results["tests"]["delete"] = self.test_delete_operation(test_key)
        results["tests"]["performance"] = self.test_performance(100)
        results["tests"]["info"] = self.get_redis_info()
        
        # Calculate overall status
        total_duration = (time.time() - start_time) * 1000
        failed_tests = [name for name, result in results["tests"].items() 
                       if result.get("status") == "fail"]
        
        results["status"] = "fail" if failed_tests else "success"
        results["failed_tests"] = failed_tests
        results["total_duration_ms"] = round(total_duration, 2)
        results["tests_passed"] = len(results["tests"]) - len(failed_tests)
        results["tests_failed"] = len(failed_tests)
        results["tests_total"] = len(results["tests"])
        
        logger.info(f"Test suite completed: {results['status']} ({results['tests_passed']}/{results['tests_total']} passed)")
        
        return results


# Global test suite instance
redis_test_suite = RedisTestSuite()
