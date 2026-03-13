# Task5 - Terraform + Linode LKE Cluster

使用 Terraform 在 Linode 建立 LKE (Linode Kubernetes Engine) Cluster，並部署 Nginx 服務透過 NodeBalancer 對外提供存取。

## 架構

```
使用者 → Linode NodeBalancer (LoadBalancer) → LKE Node → Nginx Pod
```

> **注意：** LKE Node 加入 VPC 的方式與一般 Linode Instance 不同，無法在 pool 內直接指定 subnet。LKE Node 的 VPC 設定是在 Cluster 層級，目前 Linode Terraform Provider 對此功能的支援尚不完整。

## 檔案結構

```
task5/
├── main.tf                   # Terraform 主要設定（Cluster、VPC、kubectl provider、部署資源）
├── variables.tf              # 變數宣告
├── outputs.tf                # 輸出 kubeconfig
├── deployment.yaml           # Nginx Deployment（支援 replicas 變數、回應 Pod 名稱）
├── lb-svc.yaml               # LoadBalancer Service
├── terraform.tfvars          # 變數值（不進 git）
├── terraform.tfvars.example  # 變數範本
└── linode-config.yaml        # 匯出的 kubeconfig（不進 git）
```

## 前置需求

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Linode API Token（需具備 **Kubernetes Read/Write** 權限）

## 變數說明

| 變數名稱 | 預設值 | 說明 |
|---|---|---|
| `linode_token` | - | Linode API Token（必填） |
| `replicas_number` | `2` | Nginx Pod 副本數量 |
| `region` | `ap-northeast` | Linode 部署區域 |
| `k8s_version` | `1.35` | LKE Kubernetes 版本 |
| `pool_type` | `g6-standard-1` | Node 機型 |
| `pool_count` | `1` | Node 數量 |
| `subnet_cidr` | `10.0.1.0/24` | Subnet IP 範圍 |

## 使用方式

### 1. 設定 Token

```bash
cp terraform.tfvars.example terraform.tfvars
# 編輯 terraform.tfvars，填入 linode_token
```

### 2. 建立資源

```bash
terraform init
terraform apply
```

建立 LKE Cluster 約需 3–5 分鐘。

### 3. 取得 kubeconfig 並連線

```bash
terraform output -raw kubeconfig | base64 -d > linode-config.yaml
kubectl --kubeconfig=linode-config.yaml get nodes
kubectl --kubeconfig=linode-config.yaml get svc
```

### 4. 驗證 LoadBalancer 與流量分配

```bash
# 取得 LoadBalancer 外部 IP
kubectl --kubeconfig=linode-config.yaml get svc task5-lb

# 測試流量輪流分配至不同 Pod
for i in {1..6}; do curl http://<EXTERNAL-IP>; done
```

每次回應會顯示處理請求的 Pod 名稱，例如：

```
Pod: task5-nginx-deployment-5cf9984c65-nkkpx
Pod: task5-nginx-deployment-5cf9984c65-dssc4
```

### 5. 清除資源

```bash
terraform destroy
```

> 若 Terraform state 遺失，需手動至 Linode Cloud Manager 刪除 **Kubernetes Cluster** 及 **NodeBalancer**。
