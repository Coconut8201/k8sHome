output "gitlab_root_password" {
  value = data.external.gitlab_root_password.result["password"]
  sensitive = true
}