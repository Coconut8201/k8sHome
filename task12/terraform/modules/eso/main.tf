# ===================================================================
# K8s External Secrets Operator (ESO) module
# ===================================================================
resource "helm_release" "eso" {
  name             = "eso"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = "2.2.0"
  namespace        = "eso"
  create_namespace = true

  timeout         = 600
  atomic          = true
  cleanup_on_fail = true
}
