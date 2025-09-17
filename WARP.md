# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is a DevSecOps demonstration project (`mibanco-devsecops`) that showcases a complete cloud-native deployment pipeline for a simple Flask web application on Azure Kubernetes Service (AKS). The project demonstrates infrastructure as code (IaC) practices using Terraform to provision Azure resources and deploy a containerized Python application.

## Architecture

### Application Layer
- **Flask Web App** (`app/server.py`): Simple HTTP API serving "Hola Mibanco" on port 8080
- **Container**: Dockerized with Python 3.12-slim base image, running with Gunicorn WSGI server
- **Dependencies**: Flask and Gunicorn (installed via pip in Dockerfile)

### Infrastructure Layer (Terraform)
- **Azure Container Registry (ACR)**: Private registry for application images
- **Azure Kubernetes Service (AKS)**: Managed Kubernetes cluster with single node pool
- **NGINX Ingress Controller**: HTTP/HTTPS traffic routing with LoadBalancer service
- **Kubernetes Resources**: Namespace, Deployment (2 replicas), Service, HPA (2-5 replicas based on CPU), and Ingress
- **Security**: AKS kubelet assigned AcrPull role for image access
- **Optional**: GitHub branch protection for PR-based workflows

### Key Design Patterns
- **Infrastructure as Code**: All Azure resources defined in Terraform
- **GitOps-Ready**: Terraform expects CI/CD to push images and update `image_tag` variable
- **Auto-Scaling**: Horizontal Pod Autoscaler configured for CPU-based scaling (60% threshold)
- **High Availability**: LoadBalancer with nip.io for dynamic DNS resolution
- **Separation of Concerns**: App code isolated from infrastructure definitions

## Common Development Commands

### Local Development
```powershell
# Install Python dependencies manually (no requirements.txt)
pip install flask gunicorn

# Run the Flask app locally
python app/server.py
# App will be available at http://localhost:8080

# Test the endpoint
curl http://localhost:8080  # Should return "Hola Mibanco"
```

### Container Operations
```powershell
# Build the Docker image
docker build -t mibanco-app:latest app/

# Run container locally
docker run -p 8080:8080 mibanco-app:latest

# Test containerized app
curl http://localhost:8080
```

### Terraform Infrastructure Management
```powershell
# Navigate to terraform directory
cd terraform

# Initialize Terraform (first time)
terraform init

# Plan infrastructure changes
terraform plan -var="subscription_id=YOUR_AZURE_SUBSCRIPTION_ID"

# Apply infrastructure (with required variables)
terraform apply -var="subscription_id=YOUR_AZURE_SUBSCRIPTION_ID" `
  -var="image_tag=latest"

# Destroy infrastructure
terraform destroy -var="subscription_id=YOUR_AZURE_SUBSCRIPTION_ID"

# Show current state
terraform show

# Get outputs (ACR login server, ingress hostname, kubectl hints)
terraform output
```

### Required Terraform Variables
- `subscription_id`: Azure subscription ID (required)
- `image_tag`: Container image tag, typically Git SHA from CI (default: "latest")
- Optional: `github_owner`, `github_repo`, `github_token` for branch protection

### Kubernetes Operations (Post-Deployment)
```powershell
# Configure kubectl for AKS cluster
az aks get-credentials --resource-group RESOURCE_GROUP_NAME --name AKS_CLUSTER_NAME

# Check application pods
kubectl get pods -n hola

# Check services and ingress
kubectl get svc,ing -n hola

# View application logs
kubectl logs -n hola -l app=hola

# Scale deployment manually
kubectl scale deployment hola-app -n hola --replicas=3

# Port forward for local testing
kubectl port-forward -n hola svc/hola-svc 8080:80
```

## Development Workflow

### Expected CI/CD Integration
1. **Build Phase**: CI builds Docker image from `app/Dockerfile`
2. **Push Phase**: Image pushed to ACR with Git SHA as tag
3. **Deploy Phase**: CI runs `terraform apply` with `image_tag` set to Git SHA
4. **Verification**: Application accessible via ingress hostname (using nip.io)

### Manual Testing Workflow
1. Make changes to `app/server.py`
2. Build and test Docker image locally
3. Push image to ACR manually: `docker push <acr-login-server>/hola:<tag>`
4. Update `image_tag` variable in Terraform
5. Apply Terraform changes
6. Verify deployment via kubectl and ingress endpoint

## Environment Requirements

### Prerequisites
- **Azure CLI**: For authentication and AKS credentials
- **Terraform**: >=1.6.0 (current installation: v1.12.2, upgrade recommended to 1.13.3)
- **Docker**: For building and testing containers locally
- **kubectl**: For Kubernetes cluster management
- **Python**: 3.12+ with pip for local development

### Azure Permissions Required
- Contributor or Owner role on target Azure subscription
- Ability to create: Resource Groups, Container Registries, AKS clusters, and associated networking resources

## File Structure Context
```
mibanco-devsecops/
├── app/
│   ├── Dockerfile          # Python 3.12-slim with Flask & Gunicorn
│   └── server.py           # Simple Flask API
└── terraform/
    ├── main.tf             # Primary infrastructure definitions
    ├── providers.tf        # Provider configurations (Azure, Helm, K8s, GitHub)
    ├── variables.tf        # Input variables and defaults
    └── outputs.tf          # ACR login server, ingress hostname, kubectl hints
```

Note: The terraform directory contains its own `.git` directory, suggesting it may be a separate repository or submodule for infrastructure code separation.