#!/bin/sh
Entrypoint for Celery worker,
echo "Waiting for postgres..."
while ! nc -z db 5432; do
  sleep 0.1
done
echo "PostgreSQL started"

echo "Waiting for RabbitMQ..."
while ! nc -z rabbitmq 5672; do
  sleep 0.1
done
echo "RabbitMQ started"

echo "Starting Celery worker..."
exec celery -A celery_worker.celery worker --loglevel=info