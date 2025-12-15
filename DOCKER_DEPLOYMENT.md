# Image Processing Application - Docker Deployment Guide

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Nginx (Reverse Proxy)                    │
│                      Port 80/443                             │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
┌───────▼─────────┐         ┌─────────▼────────┐
│   Flask Web     │         │  Celery Worker   │
│   Application   │         │   (Async Tasks)  │
│   Port 5000     │         │                  │
└────┬─────┬──────┘         └─────┬────┬───────┘
     │     │                      │    │
     │     │    ┌─────────────────┘    │
     │     │    │                      │
┌────▼─────▼────▼─┐              ┌────▼──────────┐
│   PostgreSQL    │              │   RabbitMQ    │
│   Database      │              │ Message Queue │
│   Port 5432     │              │  Port 5672    │
└─────────────────┘              └───────────────┘
```

## 📋 Features

### New Features Added:
- ✅ **Health Check Endpoints**: `/health`, `/health/detailed`, `/health/ready`, `/health/live`
- ✅ **Request Logging Middleware**: Automatic logging of all API requests
- ✅ **API Rate Limiting**: Protect endpoints from abuse
- ✅ **Product Search & Filtering**: Search products by name or serial number with pagination
- ✅ **System Monitoring**: CPU, memory, and disk usage metrics

### Infrastructure Features:
- ✅ **Multi-stage Dockerfile**: Optimized build with separate builder and runtime stages
- ✅ **Security**: Non-root user, minimal attack surface
- ✅ **Health Checks**: Automated container health monitoring
- ✅ **Persistent Storage**: Named volumes for database and files
- ✅ **No Hardcoded Secrets**: Environment-based configuration
- ✅ **Resource Limits**: CPU and memory constraints
- ✅ **Container Networking**: Isolated bridge network
- ✅ **Production Ready**: Nginx reverse proxy, SSL support, logging

## 🚀 Quick Start

### Prerequisites
- Docker 20.10+
- Docker Compose 2.0+
- 4GB RAM minimum
- 10GB disk space

### Development Setup

1. **Clone and Navigate to Project**
   ```bash
   cd Devops-mid
   ```

2. **Create Environment File**
   ```bash
   cp .env.example .env
   ```

3. **Edit .env File**
   ```bash
   # Update with your values
   SECRET_KEY=your-super-secret-key-here
   POSTGRES_PASSWORD=secure-password
   RABBITMQ_DEFAULT_PASS=secure-rabbitmq-password
   ```

4. **Build and Start Services**
   ```bash
   docker-compose up --build -d
   ```

5. **Initialize Database**
   ```bash
   docker-compose exec web flask db upgrade
   ```

6. **Verify Services**
   ```bash
   # Check all containers are running
   docker-compose ps
   
   # Check health
   curl http://localhost:5000/health
   ```

### Access Points
- **Web Application**: http://localhost:5000
- **Health Check**: http://localhost:5000/health
- **Detailed Health**: http://localhost:5000/health/detailed
- **RabbitMQ Management**: http://localhost:15672 (guest/guest)

## 🔒 Security Best Practices

### 1. No Hardcoded Secrets ✅
All sensitive data is stored in environment variables:
- Database credentials
- Secret keys
- API keys
- Message queue credentials

### 2. Non-Root User ✅
Application runs as `appuser` (non-root) inside containers.

### 3. Resource Limits ✅
```yaml
deploy:
  resources:
    limits:
      cpus: '1'
      memory: 1G
    reservations:
      cpus: '0.5'
      memory: 512M
```

### 4. Network Isolation ✅
Services communicate via isolated bridge network `app-network`.

### 5. Health Checks ✅
All services have health checks configured for automatic recovery.

## 📦 Persistent Storage

### Volumes Created:
- `db_data`: PostgreSQL database files
- `rabbitmq_data`: RabbitMQ messages and configuration
- `upload_data`: User uploaded files
- `output_images`: Processed images
- `output_csvs`: Generated CSV files

### Volume Management:
```bash
# List volumes
docker volume ls

# Inspect a volume
docker volume inspect image-processing-db-data

# Backup database volume
docker run --rm -v image-processing-db-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/db-backup.tar.gz /data

# Restore database volume
docker run --rm -v image-processing-db-data:/data -v $(pwd):/backup \
  alpine tar xzf /backup/db-backup.tar.gz -C /
```

## 🌐 Container Networking

### Network Verification:
```bash
# Inspect network
docker network inspect image-processing-network

# Test connectivity from web to db
docker-compose exec web nc -zv db 5432

# Test connectivity from web to rabbitmq
docker-compose exec web nc -zv rabbitmq 5672

# Check DNS resolution
docker-compose exec web nslookup db
docker-compose exec web nslookup rabbitmq
```

### Network Architecture:
- **Network Type**: Bridge
- **Network Name**: `image-processing-network`
- **DNS**: Automatic service discovery by service name
- **Isolation**: Services cannot access host network directly

## 🔧 Production Deployment

### Using Production Compose File:

1. **Create Production Environment**
   ```bash
   cp .env.example .env.production
   # Edit .env.production with production values
   ```

2. **Build Production Images**
   ```bash
   docker-compose -f docker-compose.prod.yml build
   ```

3. **Start Production Services**
   ```bash
   docker-compose -f docker-compose.prod.yml up -d
   ```

### Production Features:
- Multiple replicas (2x web, 2x celery)
- Nginx reverse proxy with SSL support
- Enhanced logging with rotation
- Resource limits and reservations
- Rolling updates (zero downtime)
- Automatic restart on failure

### SSL Configuration:
1. Place SSL certificates in `./ssl/` directory
2. Uncomment SSL server block in `nginx.conf`
3. Update domain name in nginx configuration
4. Restart nginx container

## 📊 Monitoring & Logs

### View Logs:
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f web
docker-compose logs -f celery_worker
docker-compose logs -f db

# Last 100 lines
docker-compose logs --tail=100 web
```

### Monitor Resources:
```bash
# Real-time stats
docker stats

# Container inspection
docker-compose exec web top
```

### Health Monitoring:
```bash
# Basic health check
curl http://localhost:5000/health

# Detailed health (includes DB, Celery, system resources)
curl http://localhost:5000/health/detailed

# Kubernetes-style probes
curl http://localhost:5000/health/ready   # Readiness
curl http://localhost:5000/health/live    # Liveness
```

## 🧪 Testing

### Run Tests in Container:
```bash
# Unit tests
docker-compose exec web python -m pytest tests/

# With coverage
docker-compose exec web python -m pytest --cov=app tests/
```

### Test Database Connection:
```bash
docker-compose exec web python test_db_connection.py
```

### Test Celery:
```bash
# Check Celery workers
docker-compose exec celery_worker celery -A celery_worker inspect active

# Check queues
docker-compose exec celery_worker celery -A celery_worker inspect stats
```

## 🔄 Common Operations

### Restart Services:
```bash
# All services
docker-compose restart

# Specific service
docker-compose restart web
```

### Scale Services:
```bash
# Scale celery workers
docker-compose up -d --scale celery_worker=3
```

### Update Application:
```bash
# Pull latest code
git pull

# Rebuild and restart
docker-compose up --build -d

# Run migrations
docker-compose exec web flask db upgrade
```

### Clean Up:
```bash
# Stop all services
docker-compose down

# Remove volumes (⚠️ deletes data)
docker-compose down -v

# Remove images
docker-compose down --rmi all
```

## 🐛 Troubleshooting

### Database Connection Issues:
```bash
# Check database is running
docker-compose ps db

# Check database logs
docker-compose logs db

# Test connection
docker-compose exec db psql -U postgres -d image_processing -c "SELECT 1;"
```

### Celery Not Processing Tasks:
```bash
# Check worker status
docker-compose logs celery_worker

# Restart celery
docker-compose restart celery_worker

# Check RabbitMQ
docker-compose exec rabbitmq rabbitmq-diagnostics status
```

### Port Already in Use:
```bash
# Change port in .env
echo "WEB_PORT=5001" >> .env

# Restart
docker-compose down
docker-compose up -d
```

## 📈 Performance Optimization

### Build Cache:
- Multi-stage build separates dependencies from code
- `.dockerignore` excludes unnecessary files
- Layer caching optimizes rebuild time

### Runtime Optimization:
- Alpine-based images (smaller size)
- Resource limits prevent resource exhaustion
- Health checks enable automatic recovery
- Connection pooling in application

## 🔐 Security Checklist

- [ ] Strong passwords in `.env`
- [ ] `.env` added to `.gitignore`
- [ ] Database port not exposed externally in production
- [ ] SSL/TLS enabled for HTTPS
- [ ] Rate limiting configured
- [ ] Regular security updates
- [ ] Backup strategy in place
- [ ] Log monitoring enabled

## 📝 API Endpoints

### Health & Monitoring:
- `GET /health` - Basic health check
- `GET /health/detailed` - Detailed health with dependencies
- `GET /health/ready` - Readiness probe
- `GET /health/live` - Liveness probe

### Products:
- `GET /api/products?page=1&per_page=10&search=term` - List products (with pagination and search)
- `GET /api/products/<id>` - Get product details
- `POST /api/products` - Create product
- `PUT /api/products/<id>` - Update product
- `DELETE /api/products/<id>` - Delete product

### Upload:
- `POST /api/upload` - Upload and process images

## 🎯 Next Steps

### For Kubernetes Deployment:
1. Create Kubernetes manifests from compose file
2. Use Helm charts for easier management
3. Implement Horizontal Pod Autoscaling
4. Use managed services (RDS, ElastiCache)
5. Implement service mesh (Istio/Linkerd)

### For Microservices:
1. Split into separate services (API, Worker, Auth)
2. Implement API Gateway
3. Add service discovery (Consul/Eureka)
4. Implement distributed tracing
5. Use message queue for inter-service communication

## 📚 Additional Resources

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Flask Production Deployment](https://flask.palletsprojects.com/en/latest/deploying/)
- [PostgreSQL Docker Guide](https://hub.docker.com/_/postgres)
- [RabbitMQ Docker Guide](https://hub.docker.com/_/rabbitmq)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test with Docker
4. Submit pull request

## 📄 License

[Your License Here]

---

**Built with ❤️ using Docker, Flask, PostgreSQL, and RabbitMQ**
