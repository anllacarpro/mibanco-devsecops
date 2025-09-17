# Mibanco DevSecOps Challenge - Infrastructure as Code
# Author: Miguel Angel Alarcon Llanos
# LinkedIn: https://www.linkedin.com/in/miguel-alarcon-llanos/
# Challenge: Lead DevSecOps Position


# Referencia a un resource group existente
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_container_registry" "acr" {
  name                = replace("${var.project_name}acr", "-", "")
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.project_name}-aks"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  dns_prefix          = "${var.project_name}-dns"

  default_node_pool {
    name       = "nodepool1"
    node_count = var.node_count
    vm_size    = var.node_size
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    load_balancer_sku = "standard"
  }

  depends_on = [azurerm_container_registry.acr]
}

# Allow AKS kubelet to pull images from ACR
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

# Install NGINX Ingress Controller via Helm
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
}

# Namespace for the app
resource "kubernetes_namespace" "app" {
  metadata {
    name = "hola"
  }
}

# App Deployment (image pushed by CI: <acrLoginServer>/<repo>:<tag>)
resource "kubernetes_deployment" "app" {
  metadata {
    name      = "hola-app"
    namespace = kubernetes_namespace.app.metadata[0].name
    labels = {
      app = "hola"
    }
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "hola"
      }
    }
    template {
      metadata {
        labels = {
          app = "hola"
        }
      }
      spec {
        container {
          name  = "hola"
          image = "${azurerm_container_registry.acr.login_server}/hola:${var.image_tag}"
          port {
            container_port = 8080
          }
          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
          liveness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 5
          }
          readiness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 5
          }
        }
      }
    }
  }
  depends_on = [azurerm_role_assignment.acr_pull, helm_release.ingress_nginx]
}

# Service
resource "kubernetes_service_v1" "svc" {
  metadata {
    name      = "hola-svc"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  spec {
    selector = {
      app = "hola"
    }
    port {
      port        = 80
      target_port = 8080
    }
    type = "ClusterIP"
  }
}

# HPA v2
resource "kubernetes_horizontal_pod_autoscaler_v2" "hpa" {
  metadata {
    name      = "hola-hpa"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  spec {
    min_replicas = 2
    max_replicas = 5
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.app.metadata[0].name
    }
    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type               = "Utilization"
          average_utilization = 60
        }
      }
    }
  }
}

# Get the ingress controller service to extract the external IP
data "kubernetes_service" "nginx_ingress" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
  depends_on = [helm_release.ingress_nginx]
}

# Ingress using nip.io (resolves to the controller's public IP automatically)
# Host looks like: <ip>.nip.io
resource "kubernetes_ingress_v1" "ing" {
  metadata {
    name      = "hola-ingress"
    namespace = kubernetes_namespace.app.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }
  spec {
    rule {
      host = "app.${data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].ip}.nip.io"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.svc.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
  depends_on = [data.kubernetes_service.nginx_ingress]
}

# OPTIONAL: require PR approvals on main (trunk-based)
resource "github_branch_protection" "protect_main" {
  count = var.github_repo == null ? 0 : 1

  repository_id = var.github_repo
  pattern       = "main"
  required_pull_request_reviews {
    required_approving_review_count = 1
  }
  enforce_admins = true
}
