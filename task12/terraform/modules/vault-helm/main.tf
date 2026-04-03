# ===================================================================
# Vault-Helm 服務
# ===================================================================
resource "helm_release" "vault-helm" {
  name = "vault-helm"
  repository = "https://helm.releases.hashicorp.com"
  chart = "vault"
  version = "0.32.0"
  namespace = "vault-helm"
  create_namespace = true

  timeout          = 600
  atomic           = true
  cleanup_on_fail  = true
  
  values = [file("./${path.module}/values/values.yaml")]

  set = [ 
    {
      # 啟用 dev 模式，這樣就不需要額外設定 Storage Class 和 Persistent Volume Claim
      name = "server.dev.enabled"
      value = "true"
    },
    {
      # 啟用 Ingress，讓 Vault 可以被外部訪問
      name = "server.ingress.enabled"
      value = "true"
    },
    {
      name = "server.ingress.hosts[0].host"
      value = "vault.onpremiseadvisor.com"
    },
    {
      name = "server.ingress.ingressClassName"
      value = "nginx"
    },
    {
      # 關閉任何 HTTP 請求都自動 301 轉向 HTTPS
      name  = "server.ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/ssl-redirect"
      value = "false"
      type = "string"
    },
    {
      # 啟用 CSI Provider，這樣就可以使用 Vault 的 CSI 驅動來管理 Kubernetes 的 Secret
      name = "csi.enabled"
      value = "true"
    }
  ]
}