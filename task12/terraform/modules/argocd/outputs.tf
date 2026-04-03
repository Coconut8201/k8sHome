output "argocd_admin_password" {
  value = data.external.argocd_admin_password.result["password"]
  sensitive = true
}