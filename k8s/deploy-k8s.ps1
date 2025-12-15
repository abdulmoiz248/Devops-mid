# =============================================================================
# Quick Deploy Script for Minikube
# =============================================================================
# Usage: ./deploy-k8s.ps1 [-Namespace <namespace>] [-Build]

param(
    [string]$Namespace = "image-processing-dev",
    [switch]$Build = $false,
    [switch]$Clean = $false
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Image Processing K8s Deployment Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check if minikube is running
$minikubeStatus = minikube status --format='{{.Host}}' 2>$null
if ($minikubeStatus -ne "Running") {
    Write-Host "Starting Minikube..." -ForegroundColor Yellow
    minikube start --cpus=4 --memory=8192 --driver=docker
}

# Enable required addons
Write-Host "Enabling Minikube addons..." -ForegroundColor Yellow
minikube addons enable ingress
minikube addons enable metrics-server

# Clean up if requested
if ($Clean) {
    Write-Host "Cleaning up existing resources..." -ForegroundColor Red
    kubectl delete namespace $Namespace --ignore-not-found=true
    Start-Sleep -Seconds 5
}

# Build Docker image if requested
if ($Build) {
    Write-Host "Building Docker image..." -ForegroundColor Yellow
    # Use Minikube's Docker daemon
    & minikube -p minikube docker-env --shell powershell | Invoke-Expression
    docker build -t image-processing-app:latest .
}

# Create namespace
Write-Host "Creating namespace: $Namespace" -ForegroundColor Green
kubectl apply -f k8s/namespace.yaml

# Apply ConfigMaps and Secrets
Write-Host "Applying ConfigMaps and Secrets..." -ForegroundColor Green
kubectl apply -f k8s/configmap.yaml -n $Namespace
kubectl apply -f k8s/secret.yaml -n $Namespace

# Deploy Database
Write-Host "Deploying PostgreSQL..." -ForegroundColor Green
kubectl apply -f k8s/postgres-deployment.yaml -n $Namespace

# Deploy RabbitMQ
Write-Host "Deploying RabbitMQ..." -ForegroundColor Green
kubectl apply -f k8s/rabbitmq-deployment.yaml -n $Namespace

# Wait for dependencies
Write-Host "Waiting for database to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l component=database -n $Namespace --timeout=180s

Write-Host "Waiting for message broker to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l component=message-broker -n $Namespace --timeout=180s

# Deploy Application
Write-Host "Deploying Web Application..." -ForegroundColor Green
kubectl apply -f k8s/deployment.yaml -n $Namespace

# Deploy Celery Workers
Write-Host "Deploying Celery Workers..." -ForegroundColor Green
kubectl apply -f k8s/celery-deployment.yaml -n $Namespace

# Deploy Services
Write-Host "Deploying Services..." -ForegroundColor Green
kubectl apply -f k8s/service.yaml -n $Namespace

# Deploy Ingress
Write-Host "Deploying Ingress..." -ForegroundColor Green
kubectl apply -f k8s/ingress.yaml -n $Namespace

# Wait for application pods
Write-Host "Waiting for application pods to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l component=web -n $Namespace --timeout=180s

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Show status
Write-Host "Pod Status:" -ForegroundColor Cyan
kubectl get pods -n $Namespace

Write-Host ""
Write-Host "Service Status:" -ForegroundColor Cyan
kubectl get svc -n $Namespace

Write-Host ""
Write-Host "Access the application:" -ForegroundColor Yellow
$minikubeIP = minikube ip
Write-Host "  NodePort: http://${minikubeIP}:30080" -ForegroundColor White
Write-Host "  Or run: minikube service image-processing-nodeport -n $Namespace" -ForegroundColor White
