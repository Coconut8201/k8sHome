# ===================================================================
# 初始化啟動 miniklube 服務 (4cpu, 12 GB RAM)
# ===================================================================
resource "null_resource" "minikube_start" {
    provisioner "local-exec" {
        command = <<-EOT
            if ! minikube status | grep -q "Running"; then
                minikube start \
                    --cpus 4 \
                    --memory 12288
                kubectl wait --for=condition=Ready node/minikube --timeout=120s
            else
                echo "Minikube is already running, skipping"
            fi
            minikube addons enable ingress
        EOT
    }
}

# ===================================================================
# Gitlab 服務
# ===================================================================
resource "helm_release" "gitlab" {
  depends_on = [null_resource.minikube_start]

  name = "gitlab"
  repository = "https://charts.gitlab.io"
  chart = "gitlab"
  version = "9.10.1"
  namespace = "gitlab"
  create_namespace = true

  timeout          = 900
  atomic           = true
  cleanup_on_fail  = true

  values = [file("./modules/gitlab/values/values-minikube.yaml")]
}

data "external" "gitlab_root_password" {
  depends_on = [helm_release.gitlab]

  program = ["bash", "-c", <<-EOT
    password=$(kubectl get secret gitlab-gitlab-initial-root-password \
      -ojsonpath='{.data.password}' -n gitlab | base64 --decode)
    echo "{\"password\": \"$password\"}"
  EOT
  ]
}

# ===================================================================
# Gitlab 服務使用 socat 對外開放
# ===================================================================
resource "null_resource" "socat" {
  depends_on = [helm_release.gitlab]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = <<-EOT
      sudo apt install -y socat

      MINIKUBE_IP=$(minikube ip)

      nohup sudo socat TCP-LISTEN:443,fork TCP:$MINIKUBE_IP:443 > /dev/null 2>&1 &
      nohup sudo socat TCP-LISTEN:80,fork TCP:$MINIKUBE_IP:80 > /dev/null 2>&1 &
      disown
    EOT
  }
}