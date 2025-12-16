#!/bin/sh
# Entrypoint script to initialize database and start gunicorn

# Get database host from environment variable, default to 'db' for docker-compose
DB_HOST=${DB_HOST:-db}
DB_PORT=${DB_PORT:-5432}
SKIP_DB_WAIT=${SKIP_DB_WAIT:-false}

# Wait for postgres if not skipped
if [ "$SKIP_DB_WAIT" = "false" ] || [ "$SKIP_DB_WAIT" = "False" ]; then
  echo "Waiting for postgres at $DB_HOST:$DB_PORT..."
  max_attempts=30
  attempt=0
  while ! nc -z "$DB_HOST" "$DB_PORT"; do
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
      echo "Warning: Could not connect to PostgreSQL after $max_attempts attempts. Starting anyway..."
      break
    fi
    echo "Attempt $attempt/$max_attempts: Waiting for PostgreSQL..."
    sleep 2
  done
  if [ $attempt -lt $max_attempts ]; then
    echo "PostgreSQL is available at $DB_HOST:$DB_PORT"
  fi
else
  echo "Skipping database wait (SKIP_DB_WAIT=$SKIP_DB_WAIT)"
fi

echo "Creating wsgi.py..."
cat > wsgi.py << 'EOF'
from app import create_app
application = create_app()
EOF

echo "Initializing database..."
python init_db.py || echo "Database initialization skipped or failed (non-fatal)"

echo "Starting Gunicorn..."
exec gunicorn --workers 4 --bind 0.0.0.0:5000 --access-logfile - --error-logfile - wsgi:application
