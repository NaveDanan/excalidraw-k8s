@echo off
REM Reminder: Main task is to make Excalidraw suitable for K8s deployment with Helm charts

REM Excalidraw Kubernetes Deployment Script for Windows
REM This script builds the Docker image and deploys Excalidraw to Kubernetes

setlocal enabledelayedexpansion

REM Configuration
set NAMESPACE=excalidraw
set IMAGE_NAME=excalidraw
set IMAGE_TAG=latest
set REGISTRY=
REM Set REGISTRY to your container registry (e.g., docker.io/username/)

echo [INFO] Starting Excalidraw Kubernetes deployment...

REM Check prerequisites
echo [INFO] Checking prerequisites...

docker --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not installed or not in PATH
    exit /b 1
)

kubectl version --client >nul 2>&1
if errorlevel 1 (
    echo [ERROR] kubectl is not installed or not in PATH
    exit /b 1
)

echo [SUCCESS] Prerequisites check passed

REM Build Docker image
echo [INFO] Building Docker image...

cd /d "%~dp0..\.."

if not "%REGISTRY%"=="" (
    set FULL_IMAGE_NAME=%REGISTRY%%IMAGE_NAME%:%IMAGE_TAG%
) else (
    set FULL_IMAGE_NAME=%IMAGE_NAME%:%IMAGE_TAG%
)

docker build -t "!FULL_IMAGE_NAME!" .
if errorlevel 1 (
    echo [ERROR] Failed to build Docker image
    exit /b 1
)

echo [SUCCESS] Docker image built successfully: !FULL_IMAGE_NAME!

REM Push image if registry is specified
if not "%REGISTRY%"=="" (
    echo [INFO] Pushing image to registry...
    docker push "!FULL_IMAGE_NAME!"
    if errorlevel 1 (
        echo [ERROR] Failed to push image
        exit /b 1
    )
    echo [SUCCESS] Image pushed successfully
)

REM Create namespace
echo [INFO] Creating namespace...

kubectl create namespace %NAMESPACE% --dry-run=client -o yaml | kubectl apply -f -
if errorlevel 1 (
    echo [ERROR] Failed to create namespace
    exit /b 1
)

echo [SUCCESS] Namespace created/updated successfully

REM Deploy manifests
echo [INFO] Deploying Kubernetes manifests...

kubectl apply -f "%~dp0..\manifests\namespace.yaml"
kubectl apply -f "%~dp0..\manifests\serviceaccount.yaml"
kubectl apply -f "%~dp0..\manifests\deployment.yaml"
kubectl apply -f "%~dp0..\manifests\service.yaml"
kubectl apply -f "%~dp0..\manifests\ingress.yaml"
kubectl apply -f "%~dp0..\manifests\hpa.yaml"
kubectl apply -f "%~dp0..\manifests\poddisruptionbudget.yaml"

if errorlevel 1 (
    echo [ERROR] Failed to deploy manifests
    exit /b 1
)

echo [SUCCESS] Manifests deployed successfully

REM Wait for deployment
echo [INFO] Waiting for deployment to be ready...

kubectl wait --for=condition=available --timeout=300s deployment/excalidraw -n %NAMESPACE%
if errorlevel 1 (
    echo [ERROR] Deployment failed to become ready
    exit /b 1
)

echo [SUCCESS] Deployment is ready

REM Show deployment status
echo [INFO] Deployment status:
echo.

kubectl get all -n %NAMESPACE%
echo.

echo [INFO] To access Excalidraw:
echo [INFO] 1. If using ingress: http://excalidraw.local (add to hosts file)
echo [INFO] 2. Port forward: kubectl port-forward -n %NAMESPACE% svc/excalidraw 8080:80
echo [INFO]    Then access: http://localhost:8080

echo [SUCCESS] Excalidraw deployed successfully!

endlocal