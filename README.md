# Challenge Técnico: Lead DevSecOps - Mibanco

**Desarrollado por:** Miguel Angel Alarcon Llanos  
**LinkedIn:** [miguel-alarcon-llanos](https://www.linkedin.com/in/miguel-alarcon-llanos/)  
**Challenge:** Mibanco DevSecOps Lead Position

Este proyecto implementa una solución completa de CI/CD usando GitHub Actions, Terraform, Azure Kubernetes Service (AKS) y metodología trunk-based development.

## 📋 Requisitos Completados

### ✅ Requisitos Funcionales
- [x] Aplicación "Hola Mibanco" implementada en Python/Flask
- [x] Automatización completa con GitHub Actions
- [x] Metodología trunk-based development implementada
- [x] Recursos Azure creados automáticamente (AKS, Ingress Controller, ACR)

### ✅ Requisitos Técnicos
1. [x] **AKS, Ingress Controller y ACR** - Configuración mínima con Terraform
2. [x] **Compilación y subida a ACR** - Pipeline automatizado de build y push
3. [x] **Despliegue automático** - Manifiestos K8s: deployment.yml, service.yml, hpa.yml, ingress.yml
4. [x] **Validación de pods e ingress** - Task kubectl get pods en pipeline
5. [x] **Pull Request Approvals** - Branch protection rules configuradas

## 🏗️ Arquitectura

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│   GitHub Repo   │────│ GitHub Actions   │────│   Azure Cloud       │
│                 │    │                  │    │                     │
│ • Source Code   │    │ • Build Image    │    │ • ACR (Registry)    │
│ • Terraform     │    │ • Run Terraform  │    │ • AKS (Kubernetes)  │
│ • K8s Manifests │    │ • Deploy to K8s  │    │ • Load Balancer     │
│ • CI/CD Pipeline│    │ • Validate       │    │ • Ingress           │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
```

## 🚀 Estructura del Proyecto

```
mibanco-devsecops/
├── app/                          # Aplicación Flask
│   ├── Dockerfile               # Containerización
│   └── server.py                # "Hola Mibanco" endpoint
├── terraform/                   # Infraestructura como código
│   ├── main.tf                 # Recursos Azure (AKS, ACR, etc.)
│   └── variables.tf            # Variables de configuración
├── k8s-manifests/              # Manifiestos Kubernetes
│   ├── namespace.yml           # Namespace hola
│   ├── deployment.yml          # Deployment con 2 replicas
│   ├── service.yml             # Service ClusterIP
│   ├── hpa.yml                 # Horizontal Pod Autoscaler
│   └── ingress.yml             # Ingress con nginx
├── .github/workflows/          # CI/CD Pipeline
│   └── ci-cd.yml              # GitHub Actions workflow
└── scripts/                    # Utilidades
    └── configure-branch-protection.sh
```

## 🔄 Pipeline CI/CD

### Trunk-Based Development Flow

```
feature branch ──┐
                 ├─ Pull Request ──→ Code Review ──→ main branch ──→ Deploy
develop branch ──┘                     ↓                    ↓
                                   Status Checks        Automatic
                                   • Build ✓           Deployment
                                   • Tests ✓
```

### Pipeline Stages

1. **Build Stage**
   - Checkout código fuente
   - Build imagen Docker
   - Push a Azure Container Registry
   - Ejecuta en todos los push/PR

2. **Infrastructure Stage** (solo main)
   - Terraform plan & apply
   - Crea/actualiza AKS, ACR, Load Balancer
   - Gestión idempotente de infraestructura

3. **Deploy Stage** (solo main)
   - Actualiza image tag en manifiestos
   - Deploy a Kubernetes usando kubectl
   - Espera rollout completo

4. **Validation Stage** (solo main) ⭐ **Requerido por challenge**
   - `kubectl get pods -n hola` 
   - `kubectl get ingress -n hola`
   - Validación de todos los recursos
   - Test del endpoint de la aplicación

## 🛠️ Tecnologías Utilizadas

- **Cloud**: Microsoft Azure
- **Container Orchestration**: Azure Kubernetes Service (AKS)
- **Container Registry**: Azure Container Registry (ACR)
- **Infrastructure as Code**: Terraform
- **CI/CD**: GitHub Actions
- **Application**: Python Flask + Gunicorn
- **Load Balancing**: NGINX Ingress Controller
- **Auto-scaling**: Horizontal Pod Autoscaler (HPA)

## 🔧 Configuración Inicial

### 1. Secrets de GitHub

Configure los siguientes secrets en su repositorio de GitHub:

```bash
AZURE_CREDENTIALS       # Service Principal JSON
AZURE_SUBSCRIPTION_ID   # ID de suscripción Azure
```

### 2. Azure Service Principal

```bash
az ad sp create-for-rbac --name "github-actions-sp" \
  --role contributor \
  --scopes /subscriptions/{subscription-id} \
  --sdk-auth
```

### 3. Branch Protection Rules

```bash
# Instalar GitHub CLI
gh auth login

# Ejecutar script de configuración
./scripts/configure-branch-protection.sh
```

## 🎯 Validación del Despliegue

### Comandos de Validación

```bash
# Conectar a AKS
az aks get-credentials --resource-group mibanco-devsecops-*-rg --name mibanco-devsecops-*-aks

# Validar pods (Requerido por challenge)
kubectl get pods -n hola -o wide

# Validar ingress (Requerido por challenge)  
kubectl get ingress -n hola -o wide

# Validar todos los recursos
kubectl get all -n hola
```

### Test de la Aplicación

```bash
# Via port-forward (desarrollo)
kubectl port-forward service/hola-svc 8080:80 -n hola
curl http://localhost:8080

# Via ingress (producción)
INGRESS_IP=$(kubectl get ingress hola-ingress -n hola -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://app.$INGRESS_IP.nip.io
```

**Respuesta esperada**: `Hola Mibanco`

## 📊 Recursos Azure Desplegados

| Recurso | Tipo | Configuración |
|---------|------|---------------|
| Resource Group | `azurerm_resource_group` | East US |
| AKS Cluster | `azurerm_kubernetes_cluster` | 1 node, Standard_B2s |
| Container Registry | `azurerm_container_registry` | Basic SKU, Admin enabled |
| Role Assignment | `azurerm_role_assignment` | AcrPull para AKS |
| Ingress Controller | `helm_release` | nginx-ingress 4.13.2 |

## 📈 Recursos Kubernetes

| Recurso | Archivo | Descripción |
|---------|---------|-------------|
| Namespace | `namespace.yml` | Namespace "hola" |
| Deployment | `deployment.yml` | 2 replicas, health checks |
| Service | `service.yml` | ClusterIP, puerto 80→8080 |
| HPA | `hpa.yml` | Auto-scaling 2-5 pods @ 60% CPU |
| Ingress | `ingress.yml` | NGINX, dominio externo |

## 🎯 Capturas de Pantalla

### Aplicación Funcionando
```bash
$ curl -v http://localhost:8081
* Connected to localhost (::1) port 8081
> GET / HTTP/1.1
> Host: localhost:8081
> User-Agent: curl/8.14.1
> Accept: */*
< HTTP/1.1 200 OK
< Server: gunicorn
< Date: Wed, 17 Sep 2025 19:33:27 GMT
< Content-Type: text/html; charset=utf-8
< Content-Length: 12

Hola Mibanco
```

### Validación de Pods
```bash
$ kubectl get pods -n hola -o wide
NAME                       READY   STATUS    RESTARTS   AGE     IP           NODE
hola-app-9b5759c7b-cz8d2   1/1     Running   0          23s     10.224.0.32  aks-nodepool1-18781391-vmss000000
hola-app-9b5759c7b-q6lwj   1/1     Running   0          23s     10.224.0.19  aks-nodepool1-18781391-vmss000000
```

### Validación de Ingress
```bash
$ kubectl get ingress -n hola -o wide
NAME           CLASS    HOSTS                     ADDRESS        PORTS   AGE
hola-ingress   <none>   app.4.156.246.56.nip.io   4.156.246.56   80      31m
```

## 🔒 Seguridad Implementada

- Branch protection con pull request approvals
- Service Principal con permisos mínimos
- Secrets management en GitHub Actions
- Container registry con autenticación
- Network policies en Kubernetes (básico)
- Resource limits en pods

## 🚀 Deployment Instructions

1. **Fork este repositorio**
2. **Configurar Azure Service Principal y Secrets**
3. **Push a main branch para trigger deployment**
4. **Verificar pipeline en Actions tab**
5. **Validar aplicación desplegada**

## 📚 Referencias Técnicas

- [Azure Kubernetes Service](https://docs.microsoft.com/en-us/azure/aks/)
- [GitHub Actions para Azure](https://docs.microsoft.com/en-us/azure/developer/github/github-actions)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [Trunk-based Development](https://trunkbaseddevelopment.com/)

## 👥 Autor

**Miguel Angel Alarcon Llanos**  
🔗 LinkedIn: [https://www.linkedin.com/in/miguel-alarcon-llanos/](https://www.linkedin.com/in/miguel-alarcon-llanos/)  
📧 Contacto: Disponible via LinkedIn  
🎯 **Posición**: Candidato para Lead DevSecOps - Mibanco

---

> ✅ **Estado**: Todos los requisitos del challenge completados exitosamente  
> 🎯 **Endpoint**: `http://app.{INGRESS_IP}.nip.io` → "Hola Mibanco"  
> 👨‍💻 **Desarrollado por**: Miguel Angel Alarcon Llanos
