#!/bin/bash

# Reminder: Main task is to make Excalidraw suitable for K8s deployment with Helm charts

# Setup script to make deployment scripts executable
# Run this script after cloning the repository

echo "Setting up Excalidraw Kubernetes deployment scripts..."

# Make scripts executable
chmod +x k8s/scripts/deploy.sh
chmod +x k8s/scripts/helm-deploy.sh
chmod +x k8s/scripts/build-image.sh

echo "✅ Setup completed successfully!"
echo ""
echo "Available deployment options:"
echo "1. Helm deployment (recommended):"
echo "   ./k8s/scripts/helm-deploy.sh install"
echo ""
echo "2. Direct kubectl deployment:"
echo "   ./k8s/scripts/deploy.sh"
echo ""
echo "3. Build custom image:"
echo "   ./k8s/scripts/build-image.sh [tag] [registry]"
echo ""
echo "For detailed instructions, see k8s/README.md"