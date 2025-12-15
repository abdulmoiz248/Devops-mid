"""Middleware for request logging and rate limiting"""
from flask import request, g
from functools import wraps
from datetime import datetime, timedelta
import time
import logging

logger = logging.getLogger(__name__)

# Simple in-memory rate limiting (for production, use Redis)
rate_limit_store = {}

def request_logger(app):
    """Middleware to log all incoming requests"""
    @app.before_request
    def log_request():
        g.start_time = time.time()
        logger.info(f"Request: {request.method} {request.path} from {request.remote_addr}")
    
    @app.after_request
    def log_response(response):
        if hasattr(g, 'start_time'):
            elapsed = time.time() - g.start_time
            logger.info(f"Response: {request.method} {request.path} - {response.status_code} ({elapsed:.3f}s)")
        return response
    
    return app

def rate_limit(max_requests=100, window_seconds=60):
    """
    Rate limiting decorator
    Args:
        max_requests: Maximum number of requests allowed in the time window
        window_seconds: Time window in seconds
    """
    def decorator(f):
        @wraps(f)
        def wrapped(*args, **kwargs):
            # Get client identifier (IP address)
            client_id = request.remote_addr
            current_time = datetime.utcnow()
            
            # Create key for this endpoint and client
            key = f"{f.__name__}:{client_id}"
            
            # Initialize or get existing record
            if key not in rate_limit_store:
                rate_limit_store[key] = {
                    'count': 0,
                    'reset_time': current_time + timedelta(seconds=window_seconds)
                }
            
            record = rate_limit_store[key]
            
            # Reset if window has passed
            if current_time > record['reset_time']:
                record['count'] = 0
                record['reset_time'] = current_time + timedelta(seconds=window_seconds)
            
            # Check rate limit
            if record['count'] >= max_requests:
                retry_after = int((record['reset_time'] - current_time).total_seconds())
                return {
                    'error': 'Rate limit exceeded',
                    'retry_after': retry_after
                }, 429
            
            # Increment counter
            record['count'] += 1
            
            return f(*args, **kwargs)
        return wrapped
    return decorator

def setup_middleware(app):
    """Setup all middleware for the application"""
    request_logger(app)
    return app
