# =============================================================================
# Kubernetes Deployment Guide for Image Processing Application
# =============================================================================

## Prerequisites

### For Minikube (Local Development)
```bash
# Install Minikube
# Windows: choco install minikube
# macOS: brew install minikube
# Linux: curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Start Minikube
minikube start --cpus=4 --memory=8192 --driver=docker

# Enable required addons
minikube addons enable ingress
minikube addons enable metrics-server
```

### For AWS EKS
```bash
# Install eksctl
# Configure AWS CLI with credentials
aws configure

# Create EKS cluster
eksctl create cluster \
  --name image-processing-cluster \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 5 \
  --managed
```

---

## Build and Push Docker Image

### For Minikube
```bash
# Use Minikube's Docker daemon
eval $(minikube docker-env)

# Build the image
docker build -t image-processing-app:latest .

# Verify image
docker images | grep image-processing-app
```

### For AWS ECR
```bash
# Create ECR repository
aws ecr create-repository --repository-name image-processing-app

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build and tag image
docker build -t image-processing-app:latest .
docker tag image-processing-app:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/image-processing-app:latest

# Push to ECR
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/image-processing-app:latest
```

---

## Deploy to Kubernetes

### Step 1: Create Namespaces
```bash
kubectl apply -f k8s/namespace.yaml
```

### Step 2: Deploy to Development Namespace
```bash
# Set namespace context
kubectl config set-context --current --namespace=image-processing-dev

# Apply ConfigMaps and Secrets
kubectl apply -f k8s/configmap.yaml -n image-processing-dev
kubectl apply -f k8s/secret.yaml -n image-processing-dev

# Deploy Database (PostgreSQL)
kubectl apply -f k8s/postgres-deployment.yaml -n image-processing-dev

# Deploy Message Broker (RabbitMQ)
kubectl apply -f k8s/rabbitmq-deployment.yaml -n image-processing-dev

# Wait for dependencies to be ready
kubectl wait --for=condition=ready pod -l component=database -n image-processing-dev --timeout=120s
kubectl wait --for=condition=ready pod -l component=message-broker -n image-processing-dev --timeout=120s

# Deploy Application
kubectl apply -f k8s/deployment.yaml -n image-processing-dev
kubectl apply -f k8s/celery-deployment.yaml -n image-processing-dev

# Deploy Services
kubectl apply -f k8s/service.yaml -n image-processing-dev

# (Optional) Deploy Ingress
kubectl apply -f k8s/ingress.yaml -n image-processing-dev
```

### Step 3: Deploy to Production Namespace
```bash
# Apply all resources to production
kubectl apply -f k8s/configmap.yaml -n image-processing-prod
kubectl apply -f k8s/secret.yaml -n image-processing-prod
kubectl apply -f k8s/postgres-deployment.yaml -n image-processing-prod
kubectl apply -f k8s/rabbitmq-deployment.yaml -n image-processing-prod
kubectl apply -f k8s/deployment.yaml -n image-processing-prod
kubectl apply -f k8s/celery-deployment.yaml -n image-processing-prod
kubectl apply -f k8s/service.yaml -n image-processing-prod
kubectl apply -f k8s/ingress.yaml -n image-processing-prod
kubectl apply -f k8s/hpa.yaml -n image-processing-prod
```

---

## Alternative: Deploy with Sidecar Pattern
```bash
# Use deployment with Celery as sidecar instead of separate deployment
kubectl apply -f k8s/deployment-with-sidecar.yaml -n image-processing-dev
```

---

## Verification Commands

### Check Pod Status
```bash
kubectl get pods -n image-processing-dev
kubectl get pods -n image-processing-prod
```

### Check Services
```bash
kubectl get svc -n image-processing-dev
kubectl get svc -n image-processing-prod
```

### Describe Pod (for troubleshooting)
```bash
kubectl describe pod <pod-name> -n image-processing-dev
```

### View Logs
```bash
# Web application logs
kubectl logs -f deployment/image-processing-web -n image-processing-dev

# Celery worker logs
kubectl logs -f deployment/celery-worker -n image-processing-dev

# PostgreSQL logs
kubectl logs -f deployment/postgres -n image-processing-dev
```

### Access Application

#### Minikube
```bash
# Get Minikube IP
minikube ip

# Access via NodePort
curl http://$(minikube ip):30080/health

# Or use minikube service
minikube service image-processing-nodeport -n image-processing-dev
```

#### AWS EKS (LoadBalancer)
```bash
# Get LoadBalancer URL
kubectl get svc image-processing-lb -n image-processing-dev -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

---

## Useful Commands

### Scale Deployments
```bash
kubectl scale deployment image-processing-web --replicas=3 -n image-processing-dev
kubectl scale deployment celery-worker --replicas=4 -n image-processing-dev
```

### Rollout Management
```bash
# Check rollout status
kubectl rollout status deployment/image-processing-web -n image-processing-dev

# Rollback to previous version
kubectl rollout undo deployment/image-processing-web -n image-processing-dev

# View rollout history
kubectl rollout history deployment/image-processing-web -n image-processing-dev
```

### Port Forwarding (for debugging)
```bash
# Access web application
kubectl port-forward svc/image-processing-service 8080:80 -n image-processing-dev

# Access RabbitMQ Management UI
kubectl port-forward svc/rabbitmq-service 15672:15672 -n image-processing-dev

# Access PostgreSQL
kubectl port-forward svc/postgres-service 5432:5432 -n image-processing-dev
```

---

## Clean Up

```bash
# Delete all resources in dev namespace
kubectl delete namespace image-processing-dev

# Delete all resources in prod namespace
kubectl delete namespace image-processing-prod

# Stop Minikube
minikube stop

# Delete Minikube cluster
minikube delete

# Delete EKS cluster
eksctl delete cluster --name image-processing-cluster
```

---

## Troubleshooting

### Pod stuck in Pending state
```bash
kubectl describe pod <pod-name> -n <namespace>
# Check for resource constraints or node availability
```

### Pod in CrashLoopBackOff
```bash
kubectl logs <pod-name> -n <namespace> --previous
# Check for application errors
```

### Database connection issues
```bash
# Verify PostgreSQL is running
kubectl get pods -l component=database -n <namespace>

# Check PostgreSQL logs
kubectl logs deployment/postgres -n <namespace>

# Test connection from web pod
kubectl exec -it deployment/image-processing-web -n <namespace> -- nc -zv postgres-service 5432
```

### RabbitMQ connection issues
```bash
# Verify RabbitMQ is running
kubectl get pods -l component=message-broker -n <namespace>

# Check RabbitMQ logs
kubectl logs deployment/rabbitmq -n <namespace>

# Access management UI via port-forward
kubectl port-forward svc/rabbitmq-service 15672:15672 -n <namespace>
# Then open http://localhost:15672 (guest/guest)
```
