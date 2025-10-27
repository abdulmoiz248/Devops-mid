from flask import Blueprint, request, jsonify
import csv
import re
from app.tasks.image_tasks import process_images_task
from app.models import Product, db
import uuid
import os

upload_routes = Blueprint('upload_routes', __name__)

@upload_routes.route('/upload', methods=['POST'])
def upload_csv():
    file = request.files.get('file')
    if not file or not file.filename.endswith('.csv'):
        return jsonify({"error": "No file provided or file is not a CSV"}), 400

    temp_file_path = os.path.join('tmp', f"{uuid.uuid4().hex}.csv")
    os.makedirs(os.path.dirname(temp_file_path), exist_ok=True)
    file.save(temp_file_path)

    try:
        with open(temp_file_path, 'r') as f:
            csv_reader = csv.reader(f)
            headers = next(csv_reader)

            if headers != ['Serial Number', 'Product Name', 'Input Image Urls']:
                return jsonify({"error": "CSV format is incorrect. Header row should be ['Serial Number', 'Product Name', 'Input Image Urls']"}), 400

            tasks = []
            for row in csv_reader:
                if len(row) != 3:
                    return jsonify({"error": "CSV format is incorrect. Each row should have 3 columns."}), 400

                serial_number, product_name, image_urls = row

                image_urls_list = [url.strip() for url in image_urls.split(',')]
                invalid_urls = [url for url in image_urls_list if not is_valid_url(url)]
                if invalid_urls:
                    return jsonify({"error": f"Invalid image URLs found: {', '.join(invalid_urls)}"}), 400

                product = Product.query.filter_by(serial_number=serial_number, product_name=product_name).first()
                if not product:
                    product = Product(serial_number=serial_number, product_name=product_name)
                    db.session.add(product)
                    db.session.commit()

                task = process_images_task.delay(product.id, image_urls_list)
                tasks.append(task.id)

            return jsonify({"task_ids": tasks}), 202
    except csv.Error:
        return jsonify({"error": "Error reading CSV file"}), 500
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)

def is_valid_url(url):
    regex = re.compile(
        r'^(?:http|ftp)s?://' 
        r'(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+(?:[A-Z]{2,6}\.?|[A-Z0-9-]{2,}\.?)|'  
        r'localhost|'  
        r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|'  
        r'\[?[A-F0-9]*:[A-F0-9:]+\]?)'  
        r'(?::\d+)?'  
        r'(?:/?|[/?]\S+)$', re.IGNORECASE)
    return re.match(regex, url) is not None
