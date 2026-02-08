# cilium does network policies and hubble, the aws vpc cni still handles pod ips.
# replacing the vpc cni completely makes the first apply much more fragile
resource "helm_release" "cilium" {
  name       = "cilium"
  repository = "https://helm.cilium.io"
  chart      = "cilium"
  version    = "1.20.1"
  namespace  = "kube-system"

  values = [file("${path.module}/values/cilium.yaml")]

  depends_on = [module.eks]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.9.1"
  namespace        = "argocd"
  create_namespace = true
  timeout          = 600

  values = [templatefile("${path.module}/values/argocd.yaml.tftpl", {
    env         = var.env
    base_domain = var.base_domain
  })]

  depends_on = [helm_release.cilium]
}

# the only app terraform creates, it points argocd at gitops/clusters/<env>
# and everything else in the cluster comes from there
resource "helm_release" "root_app" {
  name       = "root-app"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.5"
  namespace  = "argocd"

  values = [yamlencode({
    applications = {
      root = {
        namespace = "argocd"
        project   = "default"
        source = {
          repoURL        = var.gitops_repo
          targetRevision = "main"
          path           = "gitops/clusters/${var.env}"
        }
        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = "argocd"
        }
        syncPolicy = {
          automated = {
            prune    = true
            selfHeal = true
          }
        }
      }
    }
  })]

  depends_on = [helm_release.argocd]
}
