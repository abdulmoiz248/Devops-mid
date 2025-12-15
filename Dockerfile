# =============================================================================
# Multi-stage Dockerfile for Flask Image Processing Application
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Builder - Compile dependencies and prepare application
# -----------------------------------------------------------------------------
FROM python:3.11-slim AS builder

# Set build-time environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip wheel --no-cache-dir --wheel-dir /build/wheels -r requirements.txt && \
    pip wheel --no-cache-dir --wheel-dir /build/wheels gunicorn

# -----------------------------------------------------------------------------
# Stage 2: Runtime - Minimal production image
# -----------------------------------------------------------------------------
FROM python:3.11-slim AS runtime

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set runtime environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    FLASK_APP=app.py \
    FLASK_ENV=production \
    PATH="/home/appuser/.local/bin:$PATH"

WORKDIR /app

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    netcat-traditional \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy wheels from builder stage and install
COPY --from=builder /build/wheels /tmp/wheels
RUN pip install --no-cache-dir --no-index --find-links=/tmp/wheels /tmp/wheels/* && \
    rm -rf /tmp/wheels

# Copy application code
COPY --chown=appuser:appuser . .

# Fix line endings and make entrypoints executable
RUN apt-get update && apt-get install -y --no-install-recommends dos2unix && \
    dos2unix docker-entrypoint.sh celery-entrypoint.sh && \
    chmod +x docker-entrypoint.sh celery-entrypoint.sh && \
    apt-get remove -y dos2unix && apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Create necessary directories with proper permissions
RUN mkdir -p /tmp/uploads /tmp/output_images /tmp/output_csvs /app/instance && \
    chown -R appuser:appuser /tmp/uploads /tmp/output_images /tmp/output_csvs /app/instance /app

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Expose port
EXPOSE 5000

# Use entrypoint script
ENTRYPOINT ["./docker-entrypoint.sh"]

