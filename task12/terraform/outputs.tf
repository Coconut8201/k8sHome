output "gitlab_root_password" {
  value     = module.gitlab.gitlab_root_password
  sensitive = true
}

output "argocd_admin_password" {
  value = module.argocd.argocd_admin_password
  sensitive = true
}