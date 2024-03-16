module "traefik" {
  source = "../"

  argocd_project           = var.argocd_project
  argocd_labels            = var.argocd_labels
  destination_cluster      = var.destination_cluster
  target_revision          = var.target_revision
  enable_service_monitor   = var.enable_service_monitor
  app_autosync             = var.app_autosync
  enable_https_redirection = var.enable_https_redirection

  helm_values = concat(local.helm_values, var.helm_values)

  dependency_ids = var.dependency_ids
}

data "kubernetes_service" "traefik" {
  metadata {
    name      = replace(format("%s%s", local.helm_values.0.traefik.fullnameOverride, module.traefik.id), module.traefik.id, "")
    namespace = "traefik"
  }
}
