"""
Redis Client Wrapper
Manages Redis connections and provides error handling
"""
import redis
import logging
from config import Config

logger = logging.getLogger(__name__)


class RedisClient:
    """Redis connection manager with error handling"""
    
    def __init__(self):
        self.client = None
        self.config = Config.get_redis_config()
        
    def connect(self):
        """
        Establish connection to Redis
        Returns: True if successful, False otherwise
        """
        try:
            self.client = redis.Redis(**self.config)
            # Test connection
            self.client.ping()
            logger.info(f"Successfully connected to Redis at {self.config['host']}:{self.config['port']}")
            return True
        except redis.ConnectionError as e:
            logger.error(f"Failed to connect to Redis: {e}")
            return False
        except Exception as e:
            logger.error(f"Unexpected error connecting to Redis: {e}")
            return False
    
    def get_client(self):
        """
        Get Redis client, connecting if necessary
        Returns: Redis client instance or None
        """
        if self.client is None:
            if not self.connect():
                return None
        return self.client
    
    def is_connected(self):
        """
        Check if Redis is connected
        Returns: True if connected, False otherwise
        """
        try:
            if self.client is None:
                return False
            self.client.ping()
            return True
        except:
            return False
    
    def close(self):
        """Close Redis connection"""
        if self.client:
            try:
                self.client.close()
                logger.info("Redis connection closed")
            except Exception as e:
                logger.error(f"Error closing Redis connection: {e}")
            finally:
                self.client = None


# Global Redis client instance
redis_client = RedisClient()
