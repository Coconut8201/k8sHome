# Task12 - Kubernetes Secret 管理：Vault CSI + External Secrets Operator

## 專案簡介

本專案示範在 **Minikube** 上，透過 **Vault** 作為中央 Secret 儲存後端，搭配兩種不同的 K8s Secret 注入機制：

| 機制 | 說明 |
|------|------|
| **Secrets Store CSI Driver + Vault CSI Provider** | 將 Vault 中的設定檔（nginx config、redis config）掛載為 Volume 進入 Pod |
| **External Secrets Operator (ESO)** | 將 Vault 中的 Redis 連線憑證同步為 K8s Secret，再以環境變數注入 Pod |

整個基礎設施（GitLab、ArgoCD、Vault、ESO）皆透過 **Terraform + Helm** 自動化部署。

---

## 專案架構

```
task12/
├── helm/                        # 應用服務的 Helm Chart
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── nginx.deploy.yaml    # Nginx Deployment（config 由 CSI 掛載）
│       ├── go-server.yaml       # Go Web Server Deployment
│       ├── go-server-svc.yaml   # Go Server Service
│       ├── redis.yaml           # Redis StatefulSet（config 由 CSI 掛載）
│       ├── redis-svc.yaml       # Redis Service
│       ├── secrets.yaml         # （已註解，改用 ESO 同步）
│       └── cr/
│           ├── secretProviderClass.yaml   # CSI 對應 Vault 路徑
│           ├── vault-secret-store.yaml    # ESO SecretStore（Vault 連線設定）
│           └── vault-external-secret.yaml # ESO ExternalSecret（同步 Redis 憑證）
├── src/                         # Go Web Server 原始碼
│   ├── go-web.go                # 提供 /get API，讀取 Redis 中的 username/password
│   ├── go.mod
│   ├── go.sum
│   └── dockerfile
└── terraform/                   # 基礎設施 IaC
    ├── main.tf                  # 模組串接入口
    ├── outputs.tf               # 輸出 GitLab/ArgoCD 初始密碼
    └── modules/
        ├── gitlab/              # GitLab（含 socat port forward）
        ├── argocd/              # ArgoCD（GitOps 控制器）
        ├── secrets-store-csi-driver/  # CSI Driver
        ├── vault-helm/          # Vault Server
        ├── vault-csi-provider/  # Vault CSI Provider（橋接 CSI ↔ Vault）
        └── eso/                 # External Secrets Operator
```

---

## 架構流程圖

```
Vault（Secret 後端）
  │
  ├─── [CSI 路徑] ──────────────────────────────────────────────────────┐
  │    secret/data/nginx/default.conf                                    │
  │    secret/data/redis/redis.conf                                      │
  │         │                                                            ▼
  │    SecretProviderClass (vault-config)                   Nginx Pod（掛載 default.conf）
  │    ← Vault CSI Provider ← Secrets Store CSI Driver      Redis Pod（掛載 redis.conf）
  │
  └─── [ESO 路徑] ─────────────────────────────────────────────────────┐
       secret/redis/userdata                                            │
       (REDIS_HOST / PORT / USER / PASSWORD)                           ▼
            │                                               K8s Secret: vault-k8s-secrets
            │   ExternalSecret → SecretStore → Vault         │
            └──────────────────────────────────────────────► Go Server Pod（envFrom）
                                                              │
                                                              └─► Redis（讀取 username/password）
```

---

## 前置需求

| 工具 | 版本 |
|------|------|
| Minikube | >= 1.32 |
| kubectl | >= 1.28 |
| Terraform | >= 1.5 |
| Helm | >= 3.12 |
| Docker | >= 24 |
| socat | 透過 apt 自動安裝 |

Minikube 需求資源：**4 CPU、12 GB RAM**

---

## 執行步驟

### 1. 部署基礎設施（Terraform）

```bash
cd terraform/
terraform init
terraform apply
```

Terraform 模組按照以下順序依序部署：

```
minikube start
  → GitLab（+ socat port forward）
  → ArgoCD
  → Secrets Store CSI Driver
  → Vault（dev 模式）
  → Vault CSI Provider
  → External Secrets Operator (ESO)
```

取得初始密碼：

```bash
terraform output gitlab_root_password
terraform output argocd_admin_password
```

---

### 2. 初始化 Vault

進入 Vault UI（`http://vault.onpremiseadvisor.com`）或使用 CLI 設定以下 Secret：

```bash
# Redis 連線憑證（供 ESO 同步）
vault kv put secret/redis/userdata \
  REDIS_HOST=redis-svc \
  REDIS_PORT=6379 \
  REDIS_USER=admin \
  REDIS_PASSWORD=password

# Nginx 設定（供 CSI 掛載）
vault kv put secret/nginx/default.conf config=@default.conf

# Redis 設定（供 CSI 掛載）
vault kv put secret/redis/redis.conf config=@redis.conf
```

設定 Kubernetes Auth Method，建立 `nginx-role` 讓 CSI 可以存取 Vault：

```bash
vault auth enable kubernetes
vault write auth/kubernetes/config \
  kubernetes_host="https://$(minikube ip):8443"

vault policy write nginx-policy - <<EOF
path "secret/data/nginx/*" { capabilities = ["read"] }
path "secret/data/redis/*" { capabilities = ["read"] }
EOF

vault write auth/kubernetes/role/nginx-role \
  bound_service_account_names="*" \
  bound_service_account_namespaces="default" \
  policies=nginx-policy \
  ttl=24h
```

---

### 3. 部署應用服務

```bash
# 建立 Go Server Image
cd src/
docker build -f dockerfile -t coconut820/go-server:latest .
# 載入到 minikube
minikube image load coconut820/go-server:latest

# 部署 Helm Chart
cd helm/
helm install task12 . -n default
```

---

### 4. 驗證

```bash
# 確認所有 Pod 正常運行
kubectl get pods

# 確認 ESO 已同步 Secret
kubectl get secret vault-k8s-secrets -o yaml

# 測試 Go Server API（需要先 port-forward 或透過 nginx ingress）
kubectl port-forward svc/go-server-svc 8080:8080
curl http://localhost:8080/get
# 預期回傳：{"code":200,"username":"...","password":"..."}
```

---

## 兩種 Secret 注入方式比較

### CSI Driver（檔案掛載）

- `SecretProviderClass` 定義 Vault 路徑對應
- Pod 透過 `volumes.csi` 掛載，Secret 以**檔案形式**出現在容器內
- 適合：設定檔（nginx.conf、redis.conf）

```yaml
volumes:
  - name: nginx-config
    csi:
      driver: secrets-store.csi.k8s.io
      volumeAttributes:
        secretProviderClass: vault-config
```

### ESO（環境變數注入）

- `SecretStore` 設定 Vault 連線（token 認證）
- `ExternalSecret` 定義同步規則，自動在 K8s 內建立 `vault-k8s-secrets` Secret
- Pod 透過 `envFrom` 注入，Secret 以**環境變數形式**出現
- 適合：帳密、API Key 等 K/V 格式憑證

```yaml
envFrom:
  - secretRef:
      name: vault-k8s-secrets
```

---

## 注意事項

- Vault 目前以 **dev 模式**運行（資料不持久化，重啟後需重新設定 Secret）
- `helm/templates/cr/vault-secret-store.yaml` 中的 `token: cm9vdA==`（base64 of `root`）僅供 dev 環境測試，**正式環境請替換為短效 Token**
- SSL 憑證 / 私鑰（`ssl/`）不可上傳至版本控制

---

## 相關服務存取

| 服務 | URL |
|------|-----|
| GitLab | `http://gitlab.onpremiseadvisor.com` |
| ArgoCD | `http://argocd.onpremiseadvisor.com` |
| Vault | `http://vault.onpremiseadvisor.com` |

> 需在 `/etc/hosts` 加入 `$(minikube ip)` 對應的域名解析。
