#!/bin/sh
# Entrypoint script to initialize database and start gunicorn

echo "Waiting for postgres..."
while ! nc -z db 5432; do
  sleep 0.1
done
echo "PostgreSQL started"

echo "Creating wsgi.py..."
cat > wsgi.py << 'EOF'
from app import create_app
application = create_app()
EOF

echo "Initializing database..."
python init_db.py

echo "Starting Gunicorn..."
exec gunicorn --workers 4 --bind 0.0.0.0:5000 --access-logfile - --error-logfile - wsgi:application
