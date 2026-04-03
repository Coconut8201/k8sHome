# ===================================================================
# ArgoCD 服務
# ===================================================================
resource "helm_release" "argocd" {
  name = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart = "argo-cd"
  version = "9.4.17"
  namespace = "argocd"
  create_namespace = true

  timeout          = 600
  atomic           = true
  cleanup_on_fail  = true

  values = [file("./modules/argocd/values/values.yml")]

  set = [
    {
      name  = "global.domain"
      value = "argocd.onpremiseadvisor.com"
    },
    {
      # 取消安全模式
      name  = "configs.params.server\\.insecure"
      value = "true"
    },
    {
      name  = "server.ingress.enabled"
      value = "true"
    },
    {
      name  = "server.ingress.ingressClassName"
      value = "nginx"
    },
    {
      # 任何 HTTP 請求都自動 301 轉向 HTTPS
      name  = "server.ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/ssl-redirect"
      value = "false"
    },
  ]
}

data "external" "argocd_admin_password" {
    depends_on = [ helm_release.argocd ]
    program = ["bash", "-c", <<-EOT
        password=$(kubectl get secret argocd-initial-admin-secret \
            -ojsonpath='{.data.password}' -n argocd | base64 --decode)
        echo "{\"password\": \"$password\"}"
    EOT
    ]
}