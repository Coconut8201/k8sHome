# Task4 - In-Cluster Kubernetes Client (Go)

使用 Go 撰寫一個在 Pod 內部透過 `client-go` 列出同 namespace 所有 Pod 的程式，並透過 RBAC 授予最小權限。

## 架構

```
task4-pod (ServiceAccount: task4sa)
  └── RBAC Role: pods get/list/watch (namespace: task4)
      └── 列出 task4 namespace 下所有 Pod
```

## 檔案結構

```
task4/
├── main.go       # Go 程式，列出 task4 namespace 的所有 Pod
├── Dockerfile    # 多階段建構，產出輕量 alpine image
├── pod.yaml      # Pod 定義，使用 task4sa ServiceAccount
├── rbac.yaml     # Role + RoleBinding，賦予 Pod 讀取權限
├── go.mod
└── go.sum
```

## 使用方式

### 1. 建立 namespace 與 RBAC

```bash
kubectl create namespace task4
kubectl create serviceaccount task4sa -n task4
kubectl apply -f rbac.yaml
```

### 2. 建置並推送 Docker Image

```bash
docker build -t <your-dockerhub>/k8s-task4:latest .
docker push <your-dockerhub>/k8s-task4:latest
```

> 若使用現有 image `coconut820/k8s-task4:latest` 可跳過此步驟。

### 3. 部署 Pod

```bash
kubectl apply -f pod.yaml
```

### 4. 查看結果

```bash
kubectl logs task4-pod -n task4
```

輸出範例：
```
namespace: task4, name: task4-pod
```

### 5. 清除資源

```bash
kubectl delete -f pod.yaml
kubectl delete -f rbac.yaml
kubectl delete serviceaccount task4sa -n task4
kubectl delete namespace task4
```

## 說明

程式會自動偵測執行環境：
- **跑在 Pod 內**：使用 in-cluster config（透過 ServiceAccount token）
- **跑在本機**：fallback 到 `~/.kube/config`
