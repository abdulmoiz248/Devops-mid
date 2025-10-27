import os
import uuid
import requests
import csv
from PIL import Image as PILImage
from io import BytesIO
from app import celery, db
from app.models import Product, Image
from app.config import Config

@celery.task(bind=True)
def process_images_task(self, product_id, image_urls):
    product = Product.query.get(product_id)
    if not product:
        self.update_state(state='FAILURE', meta={'error': 'Product not found'})
        return {"error": "Product not found"}

    output_image_urls = []

    for image_url in image_urls:
        try:
            response = requests.get(image_url, timeout=10)
            response.raise_for_status()
            image = PILImage.open(BytesIO(response.content))

            output_image = image.resize((image.width // 2, image.height // 2))

            output_dir = Config.IMAGE_OUTPUT_DIR
            os.makedirs(output_dir, exist_ok=True)
            file_path = os.path.join(output_dir, f"{uuid.uuid4().hex}.jpg")
            output_image.save(file_path)

            output_image_urls.append(file_path)

            image_entry = Image(product_id=product.id, input_image_url=image_url, output_image_url=file_path)
            db.session.add(image_entry)

        except requests.exceptions.RequestException as e:
            self.update_state(state='FAILURE', meta={'error': f'Failed to download image {image_url}: {e}'})
            continue
        except Exception as e:
            self.update_state(state='FAILURE', meta={'error': f'Failed to process image {image_url}: {e}'})
            continue

    db.session.commit()

    # Generate the output CSV
    output_csv_dir = Config.OUTPUT_CSV_DIR
    os.makedirs(output_csv_dir, exist_ok=True)
    output_csv_path = os.path.join(output_csv_dir, f"{product.serial_number}_{uuid.uuid4().hex}.csv")

    with open(output_csv_path, 'w', newline='') as csvfile:
        csvwriter = csv.writer(csvfile)
        csvwriter.writerow(['Serial Number', 'Product Name', 'Input Image Urls', 'Output Image Urls'])
        for input_url, output_url in zip(image_urls, output_image_urls):
            csvwriter.writerow([product.serial_number, product.product_name, input_url, output_url])

    return {
        'serial_number': product.serial_number,
        'product_name': product.product_name,
        'input_image_urls': image_urls,
        'output_image_urls': output_image_urls,
        'output_csv_path': output_csv_path  # Return the CSV file path
    }
