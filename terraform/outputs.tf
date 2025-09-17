output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "ingress_hostname" {
  value = kubernetes_ingress_v1.ing.spec[0].rule[0].host
}

output "kubectl_hint" {
  value = "kubectl get pods -n hola && kubectl get ingress -n hola"
}
