# Task5 - Terraform + Linode LKE Cluster

使用 Terraform 在 Linode 建立 LKE (Linode Kubernetes Engine) Cluster，並部署 Nginx + LoadBalancer。

## 架構

```
curl → NodeBalancer (LoadBalancer) → nginx Pod x2
```

## 檔案結構

```
task5/
├── main.tf           # Terraform 主要設定（Cluster、kubectl provider、部署資源）
├── variables.tf      # 變數宣告
├── outputs.tf        # 輸出 kubeconfig
├── deployment.yaml   # Nginx Deployment + LoadBalancer Service
├── terraform.tfvars  # 變數值（不進 git）
└── linode-config.yaml # 匯出的 kubeconfig（不進 git）
```

## 前置需求

- [Terraform](https://developer.hashicorp.com/terraform/install)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Linode API Token（Kubernetes Read/Write 權限）

## 使用方式

### 1. 設定 Token

複製範本並填入 Linode API Token：

```bash
cp terraform.tfvars.example terraform.tfvars
# 編輯 terraform.tfvars，填入 linode_token
```

或直接建立 `terraform.tfvars`：

```hcl
linode_token = "你的token"
```

### 2. 建立資源

```bash
terraform init
terraform apply
```

### 3. 取得 kubeconfig 並連線

```bash
terraform output -raw kubeconfig | base64 -d > linode-config.yaml
kubectl --kubeconfig=linode-config.yaml get nodes
kubectl --kubeconfig=linode-config.yaml get svc
```

### 4. 取得 LoadBalancer IP 並測試

```bash
# 查看 EXTERNAL-IP
kubectl --kubeconfig=linode-config.yaml get svc task5-lb

# 測試流量分配
for i in {1..6}; do curl http://<EXTERNAL-IP>; done
```

每次回應會顯示處理請求的 Pod 名稱，確認 LoadBalancer 有輪流分配流量。

### 5. 清除資源

```bash
terraform destroy
```

> 若 state 遺失，需手動至 Linode Cloud Manager 刪除 Cluster 和 NodeBalancer。
