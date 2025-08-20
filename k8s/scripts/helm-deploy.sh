#!/bin/bash

# Reminder: Main task is to make Excalidraw suitable for K8s deployment with Helm charts

# Excalidraw Helm Deployment Script
# This script deploys Excalidraw using Helm charts

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RELEASE_NAME="excalidraw"
NAMESPACE="excalidraw"
CHART_PATH="$(dirname "$0")/../helm/excalidraw"
VALUES_FILE="$(dirname "$0")/../helm/excalidraw/values.yaml"

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
    
    if ! command -v helm &> /dev/null; then
        print_error "Helm is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
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

# Function to validate Helm chart
validate_chart() {
    print_status "Validating Helm chart..."
    
    helm lint "$CHART_PATH"
    
    if [ $? -eq 0 ]; then
        print_success "Chart validation passed"
    else
        print_error "Chart validation failed"
        exit 1
    fi
}

# Function to deploy with Helm
deploy_helm() {
    print_status "Deploying Excalidraw with Helm..."
    
    helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
        --namespace "$NAMESPACE" \
        --values "$VALUES_FILE" \
        --wait \
        --timeout 5m
    
    if [ $? -eq 0 ]; then
        print_success "Helm deployment successful"
    else
        print_error "Helm deployment failed"
        exit 1
    fi
}

# Function to show deployment status
show_status() {
    print_status "Deployment status:"
    echo ""
    
    helm status "$RELEASE_NAME" -n "$NAMESPACE"
    echo ""
    
    kubectl get all -n "$NAMESPACE"
    echo ""
    
    print_status "To access Excalidraw:"
    print_status "1. If using ingress: http://excalidraw.local (add to /etc/hosts)"
    print_status "2. Port forward: kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME 8080:80"
    print_status "   Then access: http://localhost:8080"
}

# Function to show help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  install     Install Excalidraw using Helm"
    echo "  upgrade     Upgrade existing Excalidraw installation"
    echo "  uninstall   Uninstall Excalidraw"
    echo "  status      Show deployment status"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 install"
    echo "  $0 upgrade"
    echo "  $0 status"
    echo "  $0 uninstall"
}

# Function to uninstall
uninstall() {
    print_status "Uninstalling Excalidraw..."
    
    helm uninstall "$RELEASE_NAME" -n "$NAMESPACE"
    
    if [ $? -eq 0 ]; then
        print_success "Excalidraw uninstalled successfully"
        
        read -p "Do you want to delete the namespace as well? (y/N): " delete_ns
        if [[ $delete_ns =~ ^[Yy]$ ]]; then
            kubectl delete namespace "$NAMESPACE"
            print_success "Namespace deleted"
        fi
    else
        print_error "Failed to uninstall Excalidraw"
        exit 1
    fi
}

# Main execution
main() {
    case "${1:-install}" in
        install)
            print_status "Starting Excalidraw Helm installation..."
            check_prerequisites
            create_namespace
            validate_chart
            deploy_helm
            show_status
            print_success "Excalidraw installed successfully!"
            ;;
        upgrade)
            print_status "Upgrading Excalidraw..."
            check_prerequisites
            validate_chart
            deploy_helm
            show_status
            print_success "Excalidraw upgraded successfully!"
            ;;
        uninstall)
            uninstall
            ;;
        status)
            show_status
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"