terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

provider "linode" {
  token = var.linode_token
}

# ========== linode cluster =============
resource "linode_lke_cluster" "linode-cluster" {
  label       = "linode-cluster"
  k8s_version = "1.35"
  region      = "ap-northeast"
  tags        = ["test"]

  pool {
    type  = "g6-standard-1" # 練習用最小就好
    count = 1
  }
}

locals {
  kubeconfig = yamldecode(base64decode(linode_lke_cluster.linode-cluster.kubeconfig))
}

# ========== kubectl provider =============
provider "kubectl" {
  load_config_file       = false
  host                   = local.kubeconfig.clusters[0].cluster.server
  token                  = local.kubeconfig.users[0].user.token
  cluster_ca_certificate = base64decode(local.kubeconfig.clusters[0].cluster["certificate-authority-data"])
}

data "kubectl_file_documents" "manifests" {
  content = file("${path.module}/deployment.yaml")
}

resource "kubectl_manifest" "deployment" {
  for_each  = data.kubectl_file_documents.manifests.manifests
  yaml_body = each.value
}
