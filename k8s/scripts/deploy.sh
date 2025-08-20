#!/bin/bash

# Reminder: Main task is to make Excalidraw suitable for K8s deployment with Helm charts

# Excalidraw Kubernetes Deployment Script
# This script builds the Docker image and deploys Excalidraw to Kubernetes

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="excalidraw"
IMAGE_NAME="excalidraw"
IMAGE_TAG="latest"
REGISTRY=""  # Set this to your container registry (e.g., docker.io/username/)

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to build Docker image
build_image() {
    print_status "Building Docker image..."
    
    cd "$(dirname "$0")/../.."
    
    if [ -n "$REGISTRY" ]; then
        FULL_IMAGE_NAME="${REGISTRY}${IMAGE_NAME}:${IMAGE_TAG}"
    else
        FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"
    fi
    
    docker build -t "$FULL_IMAGE_NAME" .
    
    if [ $? -eq 0 ]; then
        print_success "Docker image built successfully: $FULL_IMAGE_NAME"
    else
        print_error "Failed to build Docker image"
        exit 1
    fi
    
    # Push image if registry is specified
    if [ -n "$REGISTRY" ]; then
        print_status "Pushing image to registry..."
        docker push "$FULL_IMAGE_NAME"
        if [ $? -eq 0 ]; then
            print_success "Image pushed successfully"
        else
            print_error "Failed to push image"
            exit 1
        fi
    fi
}

# Function to create namespace
create_namespace() {
    print_status "Creating namespace..."
    
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    if [ $? -eq 0 ]; then
        print_success "Namespace created/updated successfully"
    else
        print_error "Failed to create namespace"
        exit 1
    fi
}

# Function to deploy manifests
deploy_manifests() {
    print_status "Deploying Kubernetes manifests..."
    
    # Deploy in order
    kubectl apply -f "$(dirname "$0")/../manifests/namespace.yaml"
    kubectl apply -f "$(dirname "$0")/../manifests/serviceaccount.yaml"
    kubectl apply -f "$(dirname "$0")/../manifests/deployment.yaml"
    kubectl apply -f "$(dirname "$0")/../manifests/service.yaml"
    kubectl apply -f "$(dirname "$0")/../manifests/ingress.yaml"
    kubectl apply -f "$(dirname "$0")/../manifests/hpa.yaml"
    kubectl apply -f "$(dirname "$0")/../manifests/poddisruptionbudget.yaml"
    
    if [ $? -eq 0 ]; then
        print_success "Manifests deployed successfully"
    else
        print_error "Failed to deploy manifests"
        exit 1
    fi
}

# Function to wait for deployment
wait_for_deployment() {
    print_status "Waiting for deployment to be ready..."
    
    kubectl wait --for=condition=available --timeout=300s deployment/excalidraw -n "$NAMESPACE"
    
    if [ $? -eq 0 ]; then
        print_success "Deployment is ready"
    else
        print_error "Deployment failed to become ready"
        exit 1
    fi
}

# Function to show deployment status
show_status() {
    print_status "Deployment status:"
    echo ""
    
    kubectl get all -n "$NAMESPACE"
    echo ""
    
    print_status "To access Excalidraw:"
    print_status "1. If using ingress: http://excalidraw.local (add to /etc/hosts)"
    print_status "2. Port forward: kubectl port-forward -n $NAMESPACE svc/excalidraw 8080:80"
    print_status "   Then access: http://localhost:8080"
}

# Main execution
main() {
    print_status "Starting Excalidraw Kubernetes deployment..."
    
    check_prerequisites
    build_image
    create_namespace
    deploy_manifests
    wait_for_deployment
    show_status
    
    print_success "Excalidraw deployed successfully!"
}

# Run main function
main "$@"