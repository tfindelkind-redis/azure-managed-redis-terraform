"""
Redis Client Wrapper
Manages Redis connections with Microsoft Entra ID authentication support
"""
import redis
import logging
from config import Config

logger = logging.getLogger(__name__)


class RedisClient:
    """Redis connection manager with Entra ID authentication support"""
    
    def __init__(self):
        self.client = None
        self.config = Config.get_redis_config()
        self.use_entra_id = Config.REDIS_USE_ENTRA_ID
        
    def connect(self):
        """
        Establish connection to Redis using Entra ID authentication or password
        Returns: True if successful, False otherwise
        """
        try:
            if self.use_entra_id:
                logger.info("Connecting to Redis using Entra ID managed identity authentication")
                
                # Use the official redis-entraid package for Azure Managed Redis
                from redis_entraid.cred_provider import create_from_managed_identity, ManagedIdentityType, ManagedIdentityIdType
                import os
                
                # Get the managed identity client ID from environment
                client_id = os.getenv('AZURE_CLIENT_ID')
                if not client_id:
                    raise ValueError("AZURE_CLIENT_ID environment variable is required for user-assigned managed identity")
                
                # Create credential provider for user-assigned managed identity
                # The managed identity is automatically assigned to the App Service
                credential_provider = create_from_managed_identity(
                    identity_type=ManagedIdentityType.USER_ASSIGNED,
                    resource="https://redis.azure.com/",  # Required: Azure Managed Redis resource
                    id_type=ManagedIdentityIdType.CLIENT_ID,  # Specify we're using client_id
                    id_value=client_id  # The client ID of the user-assigned managed identity
                )
                
                logger.info(f"Using user-assigned managed identity with client_id: {client_id[:8]}...")
                
                logger.info(f"Connecting to Redis at {self.config['host']}:{self.config['port']} with TLS")
                
                # Connect to Azure Managed Redis with Entra ID
                self.client = redis.Redis(
                    host=self.config['host'],
                    port=self.config['port'],
                    credential_provider=credential_provider,
                    ssl=True,  # Azure Managed Redis requires TLS
                    decode_responses=self.config['decode_responses'],
                    socket_connect_timeout=self.config['socket_connect_timeout'],
                    socket_timeout=self.config['socket_timeout'],
                    retry_on_timeout=self.config['retry_on_timeout']
                )
                
                logger.info("Redis client created with Entra ID authentication")
            else:
                logger.info("Connecting to Redis using password authentication")
                self.client = redis.Redis(**self.config)
            
            # Test connection
            self.client.ping()
            auth_method = "Entra ID token" if self.use_entra_id else "password"
            logger.info(f"Successfully connected to Redis at {self.config['host']}:{self.config['port']} using {auth_method}")
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
