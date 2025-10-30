import os
from dotenv import load_dotenv

# Load environment variables from .env file (for local development)
load_dotenv()

class Config:
    """Application configuration"""
    
    # Flask Configuration
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key-change-in-production'
    FLASK_ENV = os.environ.get('FLASK_ENV', 'development')
    DEBUG = FLASK_ENV == 'development'
    
    # Redis Configuration
    REDIS_HOSTNAME = os.environ.get('REDIS_HOSTNAME', 'localhost')
    REDIS_PORT = int(os.environ.get('REDIS_PORT', 6379))
    REDIS_PASSWORD = os.environ.get('REDIS_PASSWORD', '')
    REDIS_SSL = os.environ.get('REDIS_SSL', 'true').lower() == 'true'
    REDIS_CLUSTER_NAME = os.environ.get('REDIS_CLUSTER_NAME', 'redis-cluster')
    REDIS_USE_ENTRA_ID = os.environ.get('REDIS_USE_ENTRA_ID', 'true').lower() == 'true'
    
    # API Configuration
    API_KEY = os.environ.get('API_KEY', 'dev-api-key')
    
    # Application Insights
    APPLICATIONINSIGHTS_CONNECTION_STRING = os.environ.get(
        'APPLICATIONINSIGHTS_CONNECTION_STRING', ''
    )
    
    # Logging
    LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO')
    
    @staticmethod
    def get_redis_config():
        """Get Redis connection configuration"""
        return {
            'host': Config.REDIS_HOSTNAME,
            'port': Config.REDIS_PORT,
            'password': Config.REDIS_PASSWORD,
            'ssl': Config.REDIS_SSL,
            'decode_responses': True,
            'socket_connect_timeout': 5,
            'socket_timeout': 5,
            'retry_on_timeout': True
        }
