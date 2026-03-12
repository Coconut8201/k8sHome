# ========== 取得 kubeconfig =============
output "kubeconfig" {
  value     = linode_lke_cluster.linode-cluster.kubeconfig
  sensitive = true
}
