FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install system deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    netcat-traditional \
 && rm -rf /var/lib/apt/lists/*

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && pip install --no-cache-dir gunicorn

# Copy the project
COPY . .

# Make entrypoints executable
RUN chmod +x docker-entrypoint.sh celery-entrypoint.sh

# Ensure runtime dirs exist
RUN mkdir -p /tmp/uploads /tmp/output_images /tmp/output_csvs

ENV FLASK_APP=app.py
ENV FLASK_ENV=production

# Expose port
EXPOSE 5000

# Use entrypoint script
ENTRYPOINT ["./docker-entrypoint.sh"]
