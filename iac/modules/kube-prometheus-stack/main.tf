module "kube-prometheus-stack" {
  source = "./kube-prometheus-stack"

  cluster_name           = var.cluster_name
  base_domain            = var.base_domain
  argocd_namespace       = var.argocd_namespace
  target_revision        = var.target_revision
  cluster_issuer         = var.cluster_issuer
  namespace              = var.namespace
  deep_merge_append_list = var.deep_merge_append_list
  app_autosync           = var.app_autosync
  dependency_ids         = var.dependency_ids

  prometheus   = var.prometheus
  alertmanager = var.alertmanager
  grafana      = var.grafana

  metrics_storage_main = var.metrics_storage != null ? { storage_config = merge({ type = "s3" }, { config = var.metrics_storage }) } : null

  helm_values = concat(local.helm_values, var.helm_values)
}