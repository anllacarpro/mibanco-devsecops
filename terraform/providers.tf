terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm   = { source = "hashicorp/azurerm", version = "~> 3.110" }
    helm      = { source = "hashicorp/helm",    version = "~> 2.12" }
    kubernetes= { source = "hashicorp/kubernetes", version = "~> 2.33" }
    random    = { source = "hashicorp/random",  version = "~> 3.6" }
    # Optional: enable PR approvals via GitHub branch protection
    github    = { source = "integrations/github", version = "~> 6.2" }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Kube + Helm providers are configured after AKS exists, using its kubeconfig
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
  }
}

# Optional: GitHub provider for branch protections (PR approvals)
provider "github" {
  token = var.github_token
  owner = var.github_owner
}
