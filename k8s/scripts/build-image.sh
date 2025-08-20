#!/bin/bash

# Reminder: Main task is to make Excalidraw suitable for K8s deployment with Helm charts

# Excalidraw Docker Build and Push Script
# This script builds the Docker image and optionally pushes it to a registry

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="excalidraw"
IMAGE_TAG="${1:-latest}"
REGISTRY="${2:-}"  # Optional registry prefix
PLATFORM="linux/amd64,linux/arm64"

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

# Function to show help
show_help() {
    echo "Usage: $0 [TAG] [REGISTRY]"
    echo ""
    echo "Arguments:"
    echo "  TAG       Docker image tag (default: latest)"
    echo "  REGISTRY  Container registry prefix (optional)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Build excalidraw:latest"
    echo "  $0 v1.0.0                           # Build excalidraw:v1.0.0"
    echo "  $0 latest docker.io/username/       # Build and push to registry"
    echo "  $0 v1.0.0 ghcr.io/username/        # Build and push to GitHub registry"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    # Check if buildx is available for multi-platform builds
    if docker buildx version &> /dev/null; then
        print_status "Docker buildx available for multi-platform builds"
        BUILDX_AVAILABLE=true
    else
        print_warning "Docker buildx not available, single-platform build only"
        BUILDX_AVAILABLE=false
    fi
    
    print_success "Prerequisites check passed"
}

# Function to build image
build_image() {
    print_status "Building Docker image..."
    
    # Navigate to project root
    cd "$(dirname "$0")/../.."
    
    # Determine full image name
    if [ -n "$REGISTRY" ]; then
        FULL_IMAGE_NAME="${REGISTRY}${IMAGE_NAME}:${IMAGE_TAG}"
    else
        FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"
    fi
    
    print_status "Building image: $FULL_IMAGE_NAME"
    
    # Build image
    if [ "$BUILDX_AVAILABLE" = true ] && [ -n "$REGISTRY" ]; then
        # Multi-platform build with push
        docker buildx build \
            --platform "$PLATFORM" \
            --tag "$FULL_IMAGE_NAME" \
            --push \
            .
    else
        # Single platform build
        docker build -t "$FULL_IMAGE_NAME" .
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Docker image built successfully: $FULL_IMAGE_NAME"
    else
        print_error "Failed to build Docker image"
        exit 1
    fi
}

# Function to push image
push_image() {
    if [ -n "$REGISTRY" ] && [ "$BUILDX_AVAILABLE" != true ]; then
        print_status "Pushing image to registry..."
        
        FULL_IMAGE_NAME="${REGISTRY}${IMAGE_NAME}:${IMAGE_TAG}"
        docker push "$FULL_IMAGE_NAME"
        
        if [ $? -eq 0 ]; then
            print_success "Image pushed successfully: $FULL_IMAGE_NAME"
        else
            print_error "Failed to push image"
            exit 1
        fi
    fi
}

# Function to show image info
show_image_info() {
    print_status "Image information:"
    
    if [ -n "$REGISTRY" ]; then
        FULL_IMAGE_NAME="${REGISTRY}${IMAGE_NAME}:${IMAGE_TAG}"
    else
        FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"
    fi
    
    echo ""
    echo "Image: $FULL_IMAGE_NAME"
    
    if [ -z "$REGISTRY" ]; then
        # Show local image info
        docker images "$FULL_IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
        echo ""
        print_status "To use this image in Kubernetes:"
        echo "  helm install excalidraw ./k8s/helm/excalidraw --set image.repository=$IMAGE_NAME --set image.tag=$IMAGE_TAG"
    else
        echo ""
        print_status "To use this image in Kubernetes:"
        echo "  helm install excalidraw ./k8s/helm/excalidraw --set image.repository=${REGISTRY}${IMAGE_NAME} --set image.tag=$IMAGE_TAG"
    fi
}

# Function to test image
test_image() {
    print_status "Testing Docker image..."
    
    if [ -n "$REGISTRY" ]; then
        FULL_IMAGE_NAME="${REGISTRY}${IMAGE_NAME}:${IMAGE_TAG}"
    else
        FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"
    fi
    
    # Run container for testing
    CONTAINER_ID=$(docker run -d -p 8080:80 "$FULL_IMAGE_NAME")
    
    if [ $? -eq 0 ]; then
        print_status "Container started with ID: $CONTAINER_ID"
        print_status "Waiting for application to start..."
        sleep 5
        
        # Test if application is responding
        if curl -f http://localhost:8080 > /dev/null 2>&1; then
            print_success "Application is responding correctly"
        else
            print_warning "Application may not be responding (this might be normal for some configurations)"
        fi
        
        print_status "Stopping test container..."
        docker stop "$CONTAINER_ID" > /dev/null
        docker rm "$CONTAINER_ID" > /dev/null
        
        print_success "Image test completed"
    else
        print_error "Failed to start test container"
        exit 1
    fi
}

# Main execution
main() {
    # Check for help flag
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        show_help
        exit 0
    fi
    
    print_status "Starting Excalidraw Docker build process..."
    
    check_prerequisites
    build_image
    push_image
    show_image_info
    
    # Ask if user wants to test the image
    if [ -z "$REGISTRY" ]; then
        read -p "Do you want to test the image locally? (y/N): " test_image_choice
        if [[ $test_image_choice =~ ^[Yy]$ ]]; then
            test_image
        fi
    fi
    
    print_success "Docker build process completed successfully!"
}

# Run main function
main "$@"