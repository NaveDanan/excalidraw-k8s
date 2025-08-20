# Excalidraw Kubernetes Deployment Guide

## Main Task Objective
**Convert the Excalidraw project to run on a Kubernetes cluster with Helm charts and ensure all components are fully connected.**

## Overview

This guide provides comprehensive instructions for deploying Excalidraw (collaborative whiteboard tool) on a Kubernetes cluster. The deployment includes both traditional Kubernetes manifests and Helm charts for flexible deployment options.

## Architecture

### Application Components
- **Frontend**: React-based Excalidraw application
- **Container**: nginx serving static files
- **Port**: 80 (HTTP)
- **Scaling**: Horizontal Pod Autoscaler enabled
- **Storage**: Stateless (no persistent volumes needed)

### Kubernetes Resources
- **Namespace**: `excalidraw`
- **Deployment**: Manages Excalidraw pods
- **Service**: Internal cluster communication
- **Ingress**: External access with SSL/TLS
- **HPA**: Auto-scaling based on CPU/Memory
- **PodDisruptionBudget**: High availability
- **ServiceAccount**: Security context

## Prerequisites

### Required Tools
- Docker (for building images)
- kubectl (Kubernetes CLI)
- Helm 3.x (for Helm deployments)
- Access to a Kubernetes cluster

### Cluster Requirements
- Kubernetes 1.20+
- Ingress controller (nginx recommended)
- Metrics server (for HPA)
- Optional: cert-manager (for SSL certificates)

## Quick Start

### Option 1: Helm Deployment (Recommended)

```bash
# Clone the repository
git clone <repository-url>
cd excalidraw-k8s

# Build and deploy using Helm
./k8s/scripts/helm-deploy.sh install
```

### Option 2: Kubectl Manifests

```bash
# Build and deploy using kubectl
./k8s/scripts/deploy.sh
```

## Detailed Deployment Instructions

### 1. Build Docker Image

```bash
# Navigate to project root
cd excalidraw-k8s

# Build the image
docker build -t excalidraw:latest .

# Optional: Tag and push to registry
docker tag excalidraw:latest your-registry/excalidraw:latest
docker push your-registry/excalidraw:latest
```

### 2. Helm Deployment

#### Install
```bash
# Install with default values
helm install excalidraw ./k8s/helm/excalidraw --namespace excalidraw --create-namespace

# Install with custom values
helm install excalidraw ./k8s/helm/excalidraw \
  --namespace excalidraw \
  --create-namespace \
  --set image.repository=your-registry/excalidraw \
  --set ingress.hosts[0].host=your-domain.com
```

#### Upgrade
```bash
helm upgrade excalidraw ./k8s/helm/excalidraw --namespace excalidraw
```

#### Uninstall
```bash
helm uninstall excalidraw --namespace excalidraw
kubectl delete namespace excalidraw
```

### 3. Kubectl Deployment

```bash
# Apply all manifests
kubectl apply -f k8s/manifests/

# Or apply individually
kubectl apply -f k8s/manifests/namespace.yaml
kubectl apply -f k8s/manifests/serviceaccount.yaml
kubectl apply -f k8s/manifests/deployment.yaml
kubectl apply -f k8s/manifests/service.yaml
kubectl apply -f k8s/manifests/ingress.yaml
kubectl apply -f k8s/manifests/hpa.yaml
kubectl apply -f k8s/manifests/poddisruptionbudget.yaml
```

## Configuration

### Helm Values Configuration

Key configuration options in `values.yaml`:

```yaml
# Scaling
replicaCount: 2
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10

# Image
image:
  repository: excalidraw
  tag: latest
  pullPolicy: IfNotPresent

# Ingress
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: excalidraw.local
      paths:
        - path: /
          pathType: Prefix

# Resources
resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

### Environment Variables

- `NODE_ENV`: Application environment (production/development)
- `LOG_LEVEL`: Logging level (info/debug/error)

### Custom Configuration

To customize the deployment:

1. **Custom Domain**: Update ingress hosts in values.yaml
2. **SSL Certificates**: Configure cert-manager annotations
3. **Resource Limits**: Adjust CPU/memory limits based on load
4. **Scaling**: Modify HPA settings for auto-scaling
5. **Image Registry**: Set custom image repository

## Networking

### Internal Communication
- Service: `excalidraw.excalidraw.svc.cluster.local:80`
- Port: 80

### External Access

#### Option 1: Ingress (Production)
```bash
# Add to /etc/hosts (for local testing)
echo "127.0.0.1 excalidraw.local" >> /etc/hosts

# Access via browser
http://excalidraw.local
```

#### Option 2: Port Forward (Development)
```bash
kubectl port-forward -n excalidraw svc/excalidraw 8080:80
# Access via http://localhost:8080
```

#### Option 3: LoadBalancer (Cloud)
```yaml
service:
  type: LoadBalancer
```

## Monitoring and Health Checks

### Health Endpoints
- **Liveness**: HTTP GET `/` on port 80
- **Readiness**: HTTP GET `/` on port 80

### Monitoring
```bash
# Check deployment status
kubectl get deployments -n excalidraw

# Check pod status
kubectl get pods -n excalidraw

# View logs
kubectl logs -n excalidraw deployment/excalidraw

# Check HPA status
kubectl get hpa -n excalidraw

# Monitor events
kubectl get events -n excalidraw --sort-by='.lastTimestamp'
```

## Security

### Security Features
- **Non-root user**: Runs as user ID 1000
- **Read-only filesystem**: Root filesystem is read-only
- **Dropped capabilities**: All Linux capabilities dropped
- **Security context**: Pod and container security contexts applied
- **Network policies**: Optional network isolation

### RBAC
Minimal ServiceAccount with no additional permissions required.

## Troubleshooting

### Common Issues

#### 1. Image Pull Errors
```bash
# Check image exists
docker images | grep excalidraw

# Verify image name in deployment
kubectl describe deployment excalidraw -n excalidraw
```

#### 2. Pod Startup Issues
```bash
# Check pod logs
kubectl logs -n excalidraw -l app.kubernetes.io/name=excalidraw

# Describe pod for events
kubectl describe pods -n excalidraw -l app.kubernetes.io/name=excalidraw
```

#### 3. Ingress Not Working
```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Verify ingress configuration
kubectl describe ingress excalidraw -n excalidraw

# Check service endpoints
kubectl get endpoints excalidraw -n excalidraw
```

#### 4. HPA Not Scaling
```bash
# Check metrics server
kubectl top nodes
kubectl top pods -n excalidraw

# Verify HPA status
kubectl describe hpa excalidraw -n excalidraw
```

### Debug Commands

```bash
# Interactive pod access
kubectl run debug --rm -i --tty --image=busybox -- /bin/sh

# Port forward for debugging
kubectl port-forward -n excalidraw deployment/excalidraw 8080:80

# Check resource usage
kubectl top pods -n excalidraw

# View full pod spec
kubectl get pod <pod-name> -n excalidraw -o yaml
```

## Scaling and Performance

### Horizontal Scaling
- **Minimum**: 2 replicas for high availability
- **Maximum**: 10 replicas (configurable)
- **Metrics**: CPU 80%, Memory 80%

### Vertical Scaling
Adjust resource requests/limits based on monitoring:

```yaml
resources:
  limits:
    cpu: 500m      # Increase for higher load
    memory: 512Mi  # Increase for memory-intensive operations
  requests:
    cpu: 200m
    memory: 256Mi
```

### Performance Tuning
1. **CDN**: Use CDN for static assets
2. **Caching**: Configure nginx caching
3. **Compression**: Enable gzip compression
4. **Keep-alive**: Optimize connection handling

## Maintenance

### Updates
```bash
# Update image
helm upgrade excalidraw ./k8s/helm/excalidraw \
  --set image.tag=new-version \
  --namespace excalidraw
```

### Backup
Since Excalidraw is stateless, no data backup is required. Configuration can be backed up via:
```bash
# Export Helm values
helm get values excalidraw -n excalidraw > backup-values.yaml

# Export manifests
kubectl get all -n excalidraw -o yaml > backup-manifests.yaml
```

### Cleanup
```bash
# Remove deployment
helm uninstall excalidraw -n excalidraw
kubectl delete namespace excalidraw

# Clean up images
docker rmi excalidraw:latest
```

## Production Checklist

- [ ] Custom domain configured
- [ ] SSL/TLS certificates configured
- [ ] Resource limits appropriately set
- [ ] Monitoring and alerting configured
- [ ] Backup strategy documented
- [ ] Security scanning completed
- [ ] Load testing performed
- [ ] Disaster recovery plan created

## Support

For issues and questions:
1. Check this documentation
2. Review pod logs and events
3. Consult Kubernetes and Helm documentation
4. Check Excalidraw project documentation

---

**Remember**: This deployment makes Excalidraw suitable for production Kubernetes environments with proper scaling, security, and monitoring capabilities.