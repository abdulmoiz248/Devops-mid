from flask import Blueprint, request, jsonify

webhook = Blueprint('webhook', __name__)

@webhook.route('/webhook/notify', methods=['POST'])
def notify():
    data = request.json

    if not data or 'task_id' not in data:
        return jsonify({'error': 'Invalid data, task_id is required'}), 400

    task_id = data['task_id']

    print(f"Received webhook for task ID: {task_id}")

    return jsonify({'status': 'Webhook received', 'task_id': task_id}), 200
