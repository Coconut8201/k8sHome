provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
    context = "minikube"
  }
}

module "gitlab" {
  source = "./modules/gitlab"
}

module "argocd" {
  source     = "./modules/argocd"
  depends_on = [module.gitlab]
}

module "secrets-store-csi-driver" {
  source = "./modules/secrets-store-csi-driver"
  depends_on = [ module.argocd ]
}

module "vault-helm" {
  source = "./modules/vault-helm"
  depends_on = [ module.secrets-store-csi-driver ]
}

module "vault-csi-provider" {
  source = "./modules/vault-csi-provider"
  depends_on = [ module.vault-helm ]
}

module "eso" {
  source = "./modules/eso"
  depends_on = [ module.vault-csi-provider ]
}