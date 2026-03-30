> # 設定 Gitlab helm
## 1. 設定 namepsace
```bash
kubectl create ns gitlab
```

## 2. 建立憑證 secrets
```
kubectl create secret -n gitlab generic gitlab-tls \
    --from-file=ca.pem \
    --from-file=tls.crt=example.domain.com.pem \
    --from-file=tls.key=example.domain.com.key

```

## 3. 增加gitlab helm repo/取得 values
```bash
helm repo add gitlab https://charts.gitlab.io/
helm show values gitlab/gitlab --version 9.10.1  >> values.yaml
```

## 4. 修改 Gitlab 設定
a. 修改 gitlab ssh port 22 => 2424
![[Pasted image 20260330231721.png]]

![[Pasted image 20260330231815.png]]

## 4. helm 安裝
```bash
helm install gitlab -f values.yaml --namespace gitlab gitlab/gitlab --version 9.10.1
```



## 5. Debug
1. 因為主機沒有 loadbalance 所以改使用 `minikube tunnel` 代替
2. 設定端口轉發
```bash
sudo sysctl -w net.ipv4.ip_forward=1

sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 10.97.191.30:80
sudo iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-destination 10.97.191.30:443
sudo iptables -A FORWARD -p tcp -d 10.97.191.30 --dport 80 -j ACCEPT
sudo iptables -A FORWARD -p tcp -d 10.97.191.30 --dport 443 -j ACCEPT
sudo iptables -t nat -A POSTROUTING -o enp1s0f0 -j MASQUERADE
```

