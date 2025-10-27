# API Documentation

## 1. Upload API

### Endpoint
- **URL**: `/upload`
- **Method**: `POST`
- **Description**: Accepts a CSV file, validates its format, and returns a unique request ID.

### Request
- **Headers**:
  - `Content-Type: multipart/form-data`
- **Body**:
  - `file`: The CSV file to be uploaded.

### Response
- **Success (202 Accepted)**:
  ```json
  {
      "task_ids": ["task_id_1", "task_id_2"]
  }
  ```
- **Error (400 Bad Request)**:
  ```json
  {
      "error": "No file provided or file is not a CSV"
  }
  ```

---

## 2. Status API

### Endpoint
- **URL**: `/status/<task_id>`
- **Method**: `GET`
- **Description**: Queries the processing status using the request ID.

### Request
- **Parameters**: 
  - `task_id`: The ID of the task to check the status for.

### Response
- **Success (200 OK)**:
  ```json
  {
      "task_id": "task_id_1",
      "status": "SUCCESS",
      "result": {
          "serial_number": "001",
          "product_name": "Product A",
          "input_image_urls": ["http://example.com/image1.jpg"],
          "output_image_urls": ["/path/to/output/image1.jpg"]
      }
  }
  ```
- **Error (404 Not Found)**:
  ```json
  {
      "error": "Task not found"
  }
  ```

---

## 3. Webhook API

### Endpoint
- **URL**: `/webhook/notify`
- **Method**: `POST`
- **Description**: Handles webhook notifications when image processing is complete.

### Request
- **Headers**: 
  - `Content-Type: application/json`
- **Body**:
  ```json
  {
      "task_id": "task_id_1"
  }
  ```

### Response
- **Success (200 OK)**:
  ```json
  {
      "status": "Webhook received",
      "task_id": "task_id_1"
  }
  ```
- **Error (400 Bad Request)**:
  ```json
  {
      "error": "Invalid data, task_id is required"
  }
  ```

---

## 4. Error Handling
- **General Errors**:
  - **400 Bad Request**: Returned when the request data is invalid.
  - **404 Not Found**: Returned when a resource (e.g., task) is not found.
  - **500 Internal Server Error**: Returned when an unexpected error occurs on the server.

---

Here’s how you can structure the API examples using Postman, which you can include in your API documentation:

### **Example Requests Using Postman**

#### **5.1 Upload API**

**Postman Request:**

1. **Method**: `POST`
2. **URL**: `http://127.0.0.1:5000/upload`
3. **Headers**:
   - `Content-Type: multipart/form-data`
4. **Body**:
   - Select `form-data`.
   - Key: `file`
   - Type: `File`
   - Value: Select your CSV file (e.g., `yourfile.csv`).

**Example Response**:
```json
{
    "task_ids": ["task_id_1", "task_id_2"]
}
```

---

#### **5.2 Status API**

**Postman Request:**

1. **Method**: `GET`
2. **URL**: `http://127.0.0.1:5000/status/<task_id>`
   - Replace `<task_id>` with the actual task ID (e.g., `task_id_1`).
3. **Headers**: None required.

**Example Response**:
```json
{
    "task_id": "task_id_1",
    "status": "SUCCESS",
    "result": {
        "serial_number": "001",
        "product_name": "Product A",
        "input_image_urls": ["http://example.com/image1.jpg"],
        "output_image_urls": ["/path/to/output/image1.jpg"]
    }
}
```

---

#### **5.3 Webhook API**

**Postman Request:**

1. **Method**: `POST`
2. **URL**: `http://127.0.0.1:5000/webhook/notify`
3. **Headers**:
   - `Content-Type: application/json`
4. **Body**:
   - Select `raw`.
   - Choose `JSON` from the dropdown.
   - Enter the JSON payload:
     ```json
     {
         "task_id": "task_id_1"
     }
     ```

**Example Response**:
```json
{
    "status": "Webhook received",
    "task_id": "task_id_1"
}
```

---







