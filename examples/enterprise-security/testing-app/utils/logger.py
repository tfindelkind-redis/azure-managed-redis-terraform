"""
Logging utilities
"""
import logging
import sys
from config import Config


def setup_logging():
    """Configure application logging"""
    log_level = getattr(logging, Config.LOG_LEVEL.upper(), logging.INFO)
    
    # Create formatter
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    
    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(log_level)
    console_handler.setFormatter(formatter)
    
    # Root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(log_level)
    root_logger.addHandler(console_handler)
    
    # Suppress noisy loggers
    logging.getLogger('werkzeug').setLevel(logging.WARNING)
    
    return root_logger
