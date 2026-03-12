kubectl exec  web-server-55b8f44466-kfs47  -- rm /tmp/ready
# readinessProbe 失敗 → pod 從 endpoint 移除

kubectl exec  web-server-55b8f44466-kfs47  -- touch /tmp/ready
# readinessProbe 成功 → pod 回到 endpoint
