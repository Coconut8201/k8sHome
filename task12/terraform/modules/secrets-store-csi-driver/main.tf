# ===================================================================
# secrets-store-csi-driver 服務
# ===================================================================
resource "helm_release" "secrets-store-csi-driver" {
  name = "secrets-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart = "secrets-store-csi-driver"
  version = "1.5.6"
  namespace = "secrets-store-csi-driver"
  create_namespace = true

  timeout          = 600
  atomic           = true
  cleanup_on_fail  = true
  
  values = [file("./${path.module}/values/values.yaml")]
}