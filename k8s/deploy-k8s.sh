#!/bin/bash
# =============================================================================
# Quick Deploy Script for Minikube (Linux/macOS)
# =============================================================================
# Usage: ./deploy-k8s.sh [-n namespace] [-b] [-c]

NAMESPACE="image-processing-dev"
BUILD=false
CLEAN=false

# Parse arguments
while getopts "n:bc" opt; do
    case $opt in
        n) NAMESPACE="$OPTARG" ;;
        b) BUILD=true ;;
        c) CLEAN=true ;;
        *) echo "Usage: $0 [-n namespace] [-b build] [-c clean]"; exit 1 ;;
    esac
done

echo "========================================"
echo "Image Processing K8s Deployment Script"
echo "========================================"

# Check if minikube is running
if ! minikube status | grep -q "Running"; then
    echo "Starting Minikube..."
    minikube start --cpus=4 --memory=8192 --driver=docker
fi

# Enable required addons
echo "Enabling Minikube addons..."
minikube addons enable ingress
minikube addons enable metrics-server

# Clean up if requested
if [ "$CLEAN" = true ]; then
    echo "Cleaning up existing resources..."
    kubectl delete namespace "$NAMESPACE" --ignore-not-found=true
    sleep 5
fi

# Build Docker image if requested
if [ "$BUILD" = true ]; then
    echo "Building Docker image..."
    eval $(minikube docker-env)
    docker build -t image-processing-app:latest .
fi

# Create namespace
echo "Creating namespace: $NAMESPACE"
kubectl apply -f k8s/namespace.yaml

# Apply ConfigMaps and Secrets
echo "Applying ConfigMaps and Secrets..."
kubectl apply -f k8s/configmap.yaml -n "$NAMESPACE"
kubectl apply -f k8s/secret.yaml -n "$NAMESPACE"

# Deploy Database
echo "Deploying PostgreSQL..."
kubectl apply -f k8s/postgres-deployment.yaml -n "$NAMESPACE"

# Deploy RabbitMQ
echo "Deploying RabbitMQ..."
kubectl apply -f k8s/rabbitmq-deployment.yaml -n "$NAMESPACE"

# Wait for dependencies
echo "Waiting for database to be ready..."
kubectl wait --for=condition=ready pod -l component=database -n "$NAMESPACE" --timeout=180s

echo "Waiting for message broker to be ready..."
kubectl wait --for=condition=ready pod -l component=message-broker -n "$NAMESPACE" --timeout=180s

# Deploy Application
echo "Deploying Web Application..."
kubectl apply -f k8s/deployment.yaml -n "$NAMESPACE"

# Deploy Celery Workers
echo "Deploying Celery Workers..."
kubectl apply -f k8s/celery-deployment.yaml -n "$NAMESPACE"

# Deploy Services
echo "Deploying Services..."
kubectl apply -f k8s/service.yaml -n "$NAMESPACE"

# Deploy Ingress
echo "Deploying Ingress..."
kubectl apply -f k8s/ingress.yaml -n "$NAMESPACE"

# Wait for application pods
echo "Waiting for application pods to be ready..."
kubectl wait --for=condition=ready pod -l component=web -n "$NAMESPACE" --timeout=180s

echo ""
echo "========================================"
echo "Deployment Complete!"
echo "========================================"
echo ""

# Show status
echo "Pod Status:"
kubectl get pods -n "$NAMESPACE"

echo ""
echo "Service Status:"
kubectl get svc -n "$NAMESPACE"

echo ""
echo "Access the application:"
MINIKUBE_IP=$(minikube ip)
echo "  NodePort: http://${MINIKUBE_IP}:30080"
echo "  Or run: minikube service image-processing-nodeport -n $NAMESPACE"
