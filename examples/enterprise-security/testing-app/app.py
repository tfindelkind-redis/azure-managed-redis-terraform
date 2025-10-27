"""
Redis Testing Application
Flask-based web app for testing Azure Managed Redis connectivity
"""
from flask import Flask, render_template, jsonify, request
from functools import wraps
import logging
from datetime import datetime

from config import Config
from utils import setup_logging, redis_client
from tests import redis_test_suite

# Initialize Flask app
app = Flask(__name__)
app.config.from_object(Config)

# Setup logging
logger = setup_logging()
logger.info("Starting Redis Testing Application")

# Application Insights integration (if configured)
if Config.APPLICATIONINSIGHTS_CONNECTION_STRING:
    try:
        from opencensus.ext.azure.log_exporter import AzureLogHandler
        from opencensus.ext.flask.flask_middleware import FlaskMiddleware
        
        # Add Application Insights logging
        logger.addHandler(
            AzureLogHandler(connection_string=Config.APPLICATIONINSIGHTS_CONNECTION_STRING)
        )
        
        # Add middleware for request tracking
        middleware = FlaskMiddleware(
            app,
            exporter=None,  # Using connection string from environment
        )
        logger.info("Application Insights integration enabled")
    except ImportError:
        logger.warning("OpenCensus packages not installed, Application Insights disabled")
    except Exception as e:
        logger.error(f"Failed to initialize Application Insights: {e}")


# API Key authentication decorator
def require_api_key(f):
    """Decorator to require API key for endpoints"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        api_key = request.headers.get('X-API-Key')
        if not api_key or api_key != Config.API_KEY:
            return jsonify({
                "status": "error",
                "message": "Invalid or missing API key"
            }), 401
        return f(*args, **kwargs)
    return decorated_function


# Web UI Routes
@app.route('/')
def index():
    """Main dashboard"""
    return render_template('index.html', 
                         redis_host=Config.REDIS_HOSTNAME,
                         redis_port=Config.REDIS_PORT,
                         cluster_name=Config.REDIS_CLUSTER_NAME)


# API Routes
@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "app": "redis-test-app",
        "version": "1.0.0"
    })


@app.route('/api/redis/status', methods=['GET'])
@require_api_key
def redis_status():
    """Get Redis connection status"""
    logger.info("Checking Redis status")
    
    is_connected = redis_client.is_connected()
    
    return jsonify({
        "status": "connected" if is_connected else "disconnected",
        "timestamp": datetime.utcnow().isoformat(),
        "redis_host": Config.REDIS_HOSTNAME,
        "redis_port": Config.REDIS_PORT,
        "ssl_enabled": Config.REDIS_SSL
    })


@app.route('/api/redis/test', methods=['POST'])
@require_api_key
def run_full_test():
    """Run full Redis test suite"""
    logger.info("Running full Redis test suite")
    
    try:
        results = redis_test_suite.run_full_test_suite()
        return jsonify(results)
    except Exception as e:
        logger.error(f"Test suite failed: {e}")
        return jsonify({
            "status": "error",
            "message": str(e),
            "timestamp": datetime.utcnow().isoformat()
        }), 500


@app.route('/api/redis/test/simple', methods=['POST'])
@require_api_key
def run_simple_test():
    """Run simple ping test"""
    logger.info("Running simple ping test")
    
    try:
        result = redis_test_suite.test_connection()
        return jsonify({
            "timestamp": datetime.utcnow().isoformat(),
            "test": "ping",
            "result": result
        })
    except Exception as e:
        logger.error(f"Simple test failed: {e}")
        return jsonify({
            "status": "error",
            "message": str(e),
            "timestamp": datetime.utcnow().isoformat()
        }), 500


@app.route('/api/redis/test/write', methods=['POST'])
@require_api_key
def run_write_test():
    """Run write operation test"""
    logger.info("Running write test")
    
    try:
        data = request.get_json() or {}
        key = data.get('key', f'test:write:{int(datetime.utcnow().timestamp())}')
        value = data.get('value', 'test_value')
        
        result = redis_test_suite.test_set_operation(key, value)
        return jsonify({
            "timestamp": datetime.utcnow().isoformat(),
            "test": "write",
            "result": result
        })
    except Exception as e:
        logger.error(f"Write test failed: {e}")
        return jsonify({
            "status": "error",
            "message": str(e),
            "timestamp": datetime.utcnow().isoformat()
        }), 500


@app.route('/api/redis/test/read', methods=['POST'])
@require_api_key
def run_read_test():
    """Run read operation test"""
    logger.info("Running read test")
    
    try:
        data = request.get_json() or {}
        key = data.get('key', 'test:read')
        
        result = redis_test_suite.test_get_operation(key)
        return jsonify({
            "timestamp": datetime.utcnow().isoformat(),
            "test": "read",
            "result": result
        })
    except Exception as e:
        logger.error(f"Read test failed: {e}")
        return jsonify({
            "status": "error",
            "message": str(e),
            "timestamp": datetime.utcnow().isoformat()
        }), 500


@app.route('/api/redis/test/perf', methods=['POST'])
@require_api_key
def run_performance_test():
    """Run performance test"""
    logger.info("Running performance test")
    
    try:
        data = request.get_json() or {}
        iterations = data.get('iterations', 100)
        
        result = redis_test_suite.test_performance(iterations)
        return jsonify({
            "timestamp": datetime.utcnow().isoformat(),
            "test": "performance",
            "result": result
        })
    except Exception as e:
        logger.error(f"Performance test failed: {e}")
        return jsonify({
            "status": "error",
            "message": str(e),
            "timestamp": datetime.utcnow().isoformat()
        }), 500


@app.route('/api/redis/info', methods=['GET'])
@require_api_key
def get_redis_info():
    """Get Redis server information"""
    logger.info("Getting Redis info")
    
    try:
        result = redis_test_suite.get_redis_info()
        return jsonify({
            "timestamp": datetime.utcnow().isoformat(),
            "info": result
        })
    except Exception as e:
        logger.error(f"Failed to get Redis info: {e}")
        return jsonify({
            "status": "error",
            "message": str(e),
            "timestamp": datetime.utcnow().isoformat()
        }), 500


# Public endpoint for web UI (no API key required)
@app.route('/api/ui/test', methods=['POST'])
def run_ui_test():
    """Run test from web UI (no API key required)"""
    logger.info("Running test from web UI")
    
    try:
        data = request.get_json() or {}
        test_type = data.get('type', 'full')
        
        if test_type == 'full':
            result = redis_test_suite.run_full_test_suite()
        elif test_type == 'simple':
            result = redis_test_suite.test_connection()
        elif test_type == 'performance':
            iterations = data.get('iterations', 100)
            result = redis_test_suite.test_performance(iterations)
        else:
            return jsonify({
                "status": "error",
                "message": f"Unknown test type: {test_type}"
            }), 400
        
        return jsonify(result)
    except Exception as e:
        logger.error(f"UI test failed: {e}")
        return jsonify({
            "status": "error",
            "message": str(e),
            "timestamp": datetime.utcnow().isoformat()
        }), 500


@app.route('/api/ui/status', methods=['GET'])
def get_ui_status():
    """Get status for web UI (no API key required)"""
    is_connected = redis_client.is_connected()
    
    return jsonify({
        "connected": is_connected,
        "timestamp": datetime.utcnow().isoformat(),
        "redis_host": Config.REDIS_HOSTNAME,
        "redis_port": Config.REDIS_PORT
    })


# Error handlers
@app.errorhandler(404)
def not_found(error):
    return jsonify({
        "status": "error",
        "message": "Endpoint not found"
    }), 404


@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal server error: {error}")
    return jsonify({
        "status": "error",
        "message": "Internal server error"
    }), 500


if __name__ == '__main__':
    # For local development only
    logger.info(f"Starting development server on port 5000")
    app.run(host='0.0.0.0', port=5000, debug=Config.DEBUG)
