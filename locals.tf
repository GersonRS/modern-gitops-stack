locals {
  kubernetes_version     = "v1.27.3"
  cluster_name           = "kind"
  base_domain            = format("%s.nip.io", replace(module.traefik.external_ip, ".", "-"))
  subdomain              = "apps"
  cluster_issuer         = module.cert-manager.cluster_issuers.ca
  enable_service_monitor = true # Can be enabled after the first bootstrap.
  app_autosync           = { allow_empty = false, prune = true, self_heal = true }
}
