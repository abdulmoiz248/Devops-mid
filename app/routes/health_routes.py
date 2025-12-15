"""Health check and monitoring routes"""
from flask import Blueprint, jsonify
from app import db, celery
import psutil
import os
from datetime import datetime

health_bp = Blueprint('health', __name__)

@health_bp.route('/health', methods=['GET'])
def health_check():
    """Basic health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'service': 'image-processing-api'
    }), 200

@health_bp.route('/health/detailed', methods=['GET'])
def detailed_health_check():
    """Detailed health check with all dependencies"""
    health_status = {
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'service': 'image-processing-api',
        'checks': {}
    }
    
    # Database check
    try:
        db.session.execute(db.text('SELECT 1'))
        health_status['checks']['database'] = {'status': 'healthy'}
    except Exception as e:
        health_status['checks']['database'] = {'status': 'unhealthy', 'error': str(e)}
        health_status['status'] = 'unhealthy'
    
    # Celery broker check
    try:
        celery_status = celery.control.inspect().active()
        if celery_status is not None:
            health_status['checks']['celery'] = {
                'status': 'healthy',
                'workers': len(celery_status)
            }
        else:
            health_status['checks']['celery'] = {'status': 'degraded', 'message': 'No workers active'}
    except Exception as e:
        health_status['checks']['celery'] = {'status': 'unhealthy', 'error': str(e)}
        health_status['status'] = 'unhealthy'
    
    # System resources
    health_status['checks']['system'] = {
        'cpu_percent': psutil.cpu_percent(interval=1),
        'memory_percent': psutil.virtual_memory().percent,
        'disk_percent': psutil.disk_usage('/').percent
    }
    
    status_code = 200 if health_status['status'] == 'healthy' else 503
    return jsonify(health_status), status_code

@health_bp.route('/health/ready', methods=['GET'])
def readiness_check():
    """Kubernetes readiness probe endpoint"""
    try:
        # Check if database is accessible
        db.session.execute(db.text('SELECT 1'))
        return jsonify({'status': 'ready'}), 200
    except Exception as e:
        return jsonify({'status': 'not ready', 'error': str(e)}), 503

@health_bp.route('/health/live', methods=['GET'])
def liveness_check():
    """Kubernetes liveness probe endpoint"""
    return jsonify({'status': 'alive'}), 200
