resource "helm_release" "vault_csi_provider" {
  name       = "vault-csi"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = "0.32.0"
  namespace  = "vault-csi-provider"
  create_namespace = true

  set = [
    {
      name  = "injector.enabled"
      value = "false"
    },
    {
      name  = "server.enabled"
      value = "false"
    },
    {
      name  = "csi.enabled"
      value = "true"
    }
  ]
}
