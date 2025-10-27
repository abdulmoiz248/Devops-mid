from flask import Blueprint, request, jsonify
from celery.result import AsyncResult
from app import celery

status = Blueprint('status', __name__)

@status.route('/status/<task_id>', methods=['GET'])
def check_status(task_id):
    # Check the status of the given task ID using Celery's AsyncResult
    task_result = AsyncResult(task_id, app=celery)

    if task_result.state == 'PENDING':
        response = {
            'task_id': task_id,
            'status': 'PENDING',
            'result': None
        }
    elif task_result.state == 'PROGRESS':
        response = {
            'task_id': task_id,
            'status': 'PROGRESS',
            'result': None
        }
    elif task_result.state == 'SUCCESS':
        response = {
            'task_id': task_id,
            'status': 'SUCCESS',
            'result': task_result.result  # Assuming the result is directly the processed data
        }
    elif task_result.state == 'FAILURE':
        response = {
            'task_id': task_id,
            'status': 'FAILURE',
            'result': str(task_result.info)  # Error message from the task
        }
    else:
        response = {
            'task_id': task_id,
            'status': 'UNKNOWN',
            'result': None
        }

    return jsonify(response)
