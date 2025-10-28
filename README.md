**Image Processing System** is a Flask-based web application designed to handle image processing tasks asynchronously using Celery and Redis. The system allows users to upload CSV files containing product information and image URLs, processes the images, and stores the results in a PostgreSQL database.

## **Project Structure**

```
image-processing-system/
│
├── app/
│   ├── __init__.py             # Initializes Flask app, Celery, and other extensions
│   ├── config.py               # Configuration settings
│   ├── config_test.py          # Configuration for testing
│   ├── models.py               # Database models (Product, Image)
│   ├── routes/                 # Flask routes (upload, status, webhook)
│   │   ├── __init__.py         # Blueprint registration
│   │   ├── upload_routes.py    # Handles CSV uploads and image processing
│   │   ├── status_routes.py    # Status route for task checking
│   │   └── webhooks_routes.py  # Webhook route for notifications
│   ├── tasks/                  # Celery tasks
│   │   ├── __init__.py
│   │   └── image_tasks.py      # Asynchronous image processing tasks
│   ├── test/
│   │   ├── __init__.py
│   │   └── test_api.py         # Unit tests
│   └── app.py                  # Main entry point for the Flask app
│
├── requirements.txt            # List of dependencies
└── .venv/                      # Virtual environment (if using)
```

## **Features**

- **CSV Upload**: Upload CSV files containing product information and image URLs.
- **Image Processing**: Resize images asynchronously using Celery and Redis.
- **Database Storage**: Store product and image information in a PostgreSQL database.
- **Webhook Integration**: Handle webhook notifications for task completion.
- **Task Status**: Check the status of background tasks.

## **Installation**

### **Prerequisites**

- Python 3.x
- PostgreSQL
- Redis (for Celery)
- RabbitMQ (or another message broker)

### **Setup**

1. **Clone the repository:**

   ```bash
   git clone https://github.com/YourUsername/image-processing-system.git
   cd image-processing-system
   ```

2. **Create and activate a virtual environment:**

   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows use `.venv\Scripts\activate`
   ```

3. **Install dependencies:**

   ```bash
   pip install -r requirements.txt
   ```

4. **Set up PostgreSQL:**

   - Create a PostgreSQL database:

     ```sql
     CREATE DATABASE image_processing;
     ```

   - Update the database URI in `app/config.py` if needed:

     ```python
     SQLALCHEMY_DATABASE_URI = 'postgresql://<user>:<password>@localhost:5432/image_processing'
     ```

5. **Run migrations to create database tables:**

   ```bash
   flask db upgrade
   ```

6. **Start Redis and Celery:**

   ```bash
   redis-server  # Start Redis
   celery -A app.celery worker --loglevel=info  # Start Celery worker
   ```

7. **Run the Flask app:**

   ```bash
   flask run
   ```

## DevOps & Report

This repository also includes a DevOps report with pipeline, secrets, testing and lessons learned. See `devops_report.md` for the full write-up required by the assignment (pipeline diagram, secret management strategy, testing process and lessons learned).

## Running locally (PowerShell)

Below are quick PowerShell-friendly steps to set up and run the app locally for development. Adjust environment values as appropriate.

1. Create and activate a virtual environment:

```powershell
python -m venv .venv; .\.venv\Scripts\Activate.ps1
```

2. Install dependencies:

```powershell
pip install -r requirements.txt
```

3. Set required environment variables (example):

```powershell
$env:FLASK_APP = 'app.app:app'
$env:FLASK_ENV = 'development'
$env:DATABASE_URL = 'postgresql://<user>:<password>@localhost:5432/image_processing'
# Broker & backend for Celery
$env:CELERY_BROKER_URL = 'redis://localhost:6379/0'
$env:CELERY_RESULT_BACKEND = 'redis://localhost:6379/0'
```

4. Run migrations (if using Flask-Migrate / Alembic):

```powershell
flask db upgrade
```

5. Start a Celery worker (in a separate terminal):

```powershell
celery -A app.celery worker --loglevel=info
```

6. Start the Flask app:

```powershell
flask run
```

## Tests

Run unit tests with pytest:

```powershell
pytest -q
```

If your tests require services (Postgres, Redis), ensure those services are running or use test-specific configuration in `app/config_test.py`.


## **Usage**

- **Upload CSV**: Use the `/upload` endpoint to upload CSV files containing product and image URLs.
- **Check Task Status**: Use the `/status` endpoint to check the status of background tasks.
- **Webhook Notifications**: The `/webhook/notify` endpoint handles webhook notifications for task completion.

## **Example CSV Format**

```csv
Serial Number,Product Name,Input Image Urls
12345,Product A,http://example.com/image1.jpg,http://example.com/image2.jpg
67890,Product B,http://example.com/image3.jpg
```

## **Testing**

To run the unit tests:

```bash
pytest
```

## **License**

This project is licensed under the MIT License.

## **Contributing**

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

---

### **Customization**

- **Replace** placeholders like `YourUsername` in the GitHub URL with your actual GitHub username.
- **Modify** the example CSV file format or other sections based on your actual project needs.
```

You can copy and paste this formatted text directly into your GitHub repository’s `README.md` file.
