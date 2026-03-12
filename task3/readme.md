docker build -t coconut820/nginx-probe:latest .

docker push coconut820/nginx-probe:latest

# 停止流量
kubectl exec <target-pod-name> -- \
  bash -c "sed -i 's/return 200/return 500/' /etc/nginx/conf.d/default.conf && nginx -s reload"

# 恢復流量
kubectl exec <target-pod-name> -- \
  bash -c "sed -i 's/return 500/return 200/' /etc/nginx/conf.d/default.conf && nginx -s reload"
