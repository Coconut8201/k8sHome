terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 3.10"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

provider "linode" {
  token       = var.linode_token
  api_version = "v4beta"
}

# ======== VPC ========
resource "linode_vpc" "vpc" {
  label       = "linode-vpc"
  region      = var.region
  description = "VPC for linode project"
}

resource "linode_vpc_subnet" "sbt" {
  vpc_id = linode_vpc.vpc.id
  label  = "linode-sbt"
  ipv4   = var.subnet_cidr
}

# ========== linode cluster =============
resource "linode_lke_cluster" "linode-cluster" {
  label       = "linode-cluster"
  k8s_version = var.k8s_version
  region      = var.region
  tags        = ["test"]

  subnet_id = linode_vpc_subnet.sbt.id
  vpc_id    = linode_vpc.vpc.id

  pool {
    type  = var.pool_type
    count = var.pool_count
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

# ======== Deployment ========
data "kubectl_file_documents" "deployment" {
  content = templatefile("${path.module}/deployment.yaml", {
    replicas_number = var.replicas_number
  })
}

resource "kubectl_manifest" "deployment" {
  for_each   = data.kubectl_file_documents.deployment.manifests
  yaml_body  = each.value
  depends_on = [linode_lke_cluster.linode-cluster]
}

# ======== Service ========
data "kubectl_file_documents" "service" {
  content = file("${path.module}/lb-svc.yaml")
}

resource "kubectl_manifest" "service" {
  for_each   = data.kubectl_file_documents.service.manifests
  yaml_body  = each.value
  depends_on = [linode_lke_cluster.linode-cluster]
}
