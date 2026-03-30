provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

# 這邊控制 chart 的版本
resource "helm_release" "my-app" {
  name             = "my-app"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "nginx"
  version          = "15.0.0"
  create_namespace = true

  # 等待所有資源 Ready <== 不要這麼做因為此為非正式環境，可能會因為缺少一些東西導致服務卡住
  cleanup_on_fail = true # 失敗自動清理
  upgrade_install = true # helm upgrade --install
  values = [
    # yamlencode 會覆蓋掉 values 檔案匯入
    file("${path.module}/values/base.yaml"),
  ]
}
