# ========== 取得 kubeconfig =============
output "kubeconfig" {
  value     = linode_lke_cluster.linode-cluster.kubeconfig
  sensitive = true
}

# # ======== VPC setting ========
# output "vpc_id" {
#   value = linode_vpc.vpc.id
# }

# output "subnet_id" {
#   value = linode_vpc_subnet.sbt.id
# }
