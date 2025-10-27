### **Asynchronous Workers Documentation**

#### **1. Celery Setup**

**1.1 Celery Configuration**
- **Broker**: RabbitMQ or Redis is used as the message broker to handle task queues.
  - **Broker URL**: `CELERY_BROKER_URL = 'amqp://localhost//'`
- **Result Backend**: Tracks the status and results of tasks.
  - **Result Backend URL**: `CELERY_RESULT_BACKEND = 'rpc://'`

**1.2 Task Binding**
- Celery tasks are bound to the Celery app (`bind=True`), allowing them to access their state and manage retries.

---

#### **2. Image Processing Task**

**2.1 Task Definition**
- **Task Name**: `process_images_task`
- **Input Parameters**:
  - `product_id`: The ID of the product for which images are being processed.
  - `image_urls`: A list of image URLs to be processed.
- **Output**:
  - A dictionary containing the serial number, product name, input image URLs, and output image URLs.

**2.2 Task Flow**

1. **Query Product**:
   - The task queries the `Product` model using `product_id`.
   - If the product is not found, the task updates its state to `FAILURE`.

2. **Image Download and Processing**:
   - For each image URL:
     - Download the image using the `requests` library.
     - Resize the image to 50% of its original size using `PIL.Image`.
     - Save the processed image to the output directory.

3. **Database Interaction**:
   - The task saves processed image data to the `Image` model in the PostgreSQL database.
   - It commits the transaction to the database after processing each image.

4. **Return and State Update**:
   - The task returns a dictionary with the processing results.
   - The task updates its state to `SUCCESS` upon successful completion.

**Example Code**:
```python
@celery.task(bind=True)
def process_images_task(self, product_id, image_urls):
    # Task implementation
```

---

#### **3. Task Status Management**

**3.1 Task States**
- **PENDING**: The task has been received but not yet started.
- **PROGRESS**: The task is currently being executed.
- **SUCCESS**: The task has completed successfully.
- **FAILURE**: The task encountered an error during execution.

**3.2 Error Handling and Retries**
- **Error Handling**:
  - If an image download fails, the task logs the error and continues processing the next image.
  - If a critical error occurs (e.g., product not found), the task updates its state to `FAILURE` and exits.
- **Retries**:
  - The task is configured to retry in case of transient errors like network issues. You can define the retry logic directly in the task decorator.

**Example Retry Configuration**:
```python
@celery.task(bind=True, max_retries=3)
def process_images_task(self, product_id, image_urls):
    # Task implementation with retry logic
```

---

#### **4. Integration with Celery**

- **Task Binding**:
  - Tasks are bound to the Celery app, allowing them to manage their state and handle retries.
- **Logging**:
  - The task logs important events and errors, which are crucial for monitoring and debugging.

**Example Code for Task**:
```python
@celery.task(bind=True)
def process_images_task(self, product_id, image_urls):
    from app.config import Config

    # Product query
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

    return {
        'serial_number': product.serial_number,
        'product_name': product.product_name,
        'input_image_urls': image_urls,
        'output_image_urls': output_image_urls
    }
```

---
