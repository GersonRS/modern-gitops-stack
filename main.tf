module "kind" {
  source             = "./modules/kind"
  cluster_name       = local.cluster_name
  kubernetes_version = local.kubernetes_version
}

module "metallb" {
  source = "./modules/metallb"
  subnet = module.kind.kind_subnet
}

module "argocd_bootstrap" {
  source     = "./modules/argocd_bootstrap"
  depends_on = [module.kind]
}

module "traefik" {
  source                 = "./modules/traefik/kind"
  cluster_name           = local.cluster_name
  base_domain            = "172-18-0-100.nip.io"
  argocd_namespace       = module.argocd_bootstrap.argocd_namespace
  enable_service_monitor = local.enable_service_monitor
  target_revision        = local.target_revision
  dependency_ids = {
    argocd = module.argocd_bootstrap.id
  }
}

module "cert-manager" {
  source                 = "./modules/cert-manager/self-signed"
  argocd_namespace       = module.argocd_bootstrap.argocd_namespace
  enable_service_monitor = local.enable_service_monitor
  target_revision        = local.target_revision
  dependency_ids = {
    argocd = module.argocd_bootstrap.id
  }
}

module "keycloak" {
  source           = "./modules/keycloak"
  cluster_name     = local.cluster_name
  base_domain      = local.base_domain
  cluster_issuer   = local.cluster_issuer
  argocd_namespace = module.argocd_bootstrap.argocd_namespace
  target_revision  = local.target_revision
  dependency_ids = {
    traefik      = module.traefik.id
    cert-manager = module.cert-manager.id
  }
}

module "oidc" {
  source         = "./modules/oidc"
  cluster_name   = local.cluster_name
  base_domain    = local.base_domain
  cluster_issuer = local.cluster_issuer
  dependency_ids = {
    keycloak = module.keycloak.id
  }
}

module "minio" {
  source                 = "./modules/minio"
  cluster_name           = local.cluster_name
  base_domain            = local.base_domain
  cluster_issuer         = local.cluster_issuer
  argocd_namespace       = module.argocd_bootstrap.argocd_namespace
  enable_service_monitor = local.enable_service_monitor
  oidc                   = module.oidc.oidc
  target_revision        = local.target_revision
  dependency_ids = {
    traefik      = module.traefik.id
    cert-manager = module.cert-manager.id
    oidc         = module.oidc.id
  }
}

module "loki-stack" {
  source           = "./modules/loki-stack/kind"
  argocd_namespace = module.argocd_bootstrap.argocd_namespace
  logs_storage = {
    bucket_name = "loki-bucket"
    endpoint    = module.minio.cluster_dns
    access_key  = module.minio.minio_root_user_credentials.username
    secret_key  = module.minio.minio_root_user_credentials.password
  }
  target_revision = local.target_revision
  dependency_ids = {
    minio = module.minio.id
  }
}

module "thanos" {
  source           = "./modules/thanos/kind"
  cluster_name     = local.cluster_name
  base_domain      = local.base_domain
  cluster_issuer   = local.cluster_issuer
  argocd_namespace = module.argocd_bootstrap.argocd_namespace
  metrics_storage = {
    bucket_name = "thanos-bucket"
    endpoint    = module.minio.cluster_dns
    access_key  = module.minio.minio_root_user_credentials.username
    secret_key  = module.minio.minio_root_user_credentials.password
  }
  thanos = {
    oidc = module.oidc.oidc
  }
  target_revision = local.target_revision
  dependency_ids = {
    argocd       = module.argocd_bootstrap.id
    traefik      = module.traefik.id
    cert-manager = module.cert-manager.id
    minio        = module.minio.id
    keycloak     = module.keycloak.id
    oidc         = module.oidc.id
  }
}

module "kube-prometheus-stack" {
  source           = "./modules/kube-prometheus-stack/kind"
  cluster_name     = local.cluster_name
  base_domain      = local.base_domain
  cluster_issuer   = local.cluster_issuer
  argocd_namespace = module.argocd_bootstrap.argocd_namespace
  metrics_storage = {
    bucket_name = "thanos-bucket"
    endpoint    = module.minio.cluster_dns
    access_key  = module.minio.minio_root_user_credentials.username
    secret_key  = module.minio.minio_root_user_credentials.password
  }
  prometheus = {
    oidc = module.oidc.oidc
  }
  alertmanager = {
    oidc = module.oidc.oidc
  }
  grafana = {
    oidc = module.oidc.oidc
  }
  target_revision = local.target_revision
  dependency_ids = {
    traefik      = module.traefik.id
    cert-manager = module.cert-manager.id
    minio        = module.minio.id
    oidc         = module.oidc.id
  }
}

module "argocd" {
  source                   = "./modules/argocd"
  base_domain              = local.base_domain
  cluster_name             = local.cluster_name
  cluster_issuer           = local.cluster_issuer
  server_secretkey         = module.argocd_bootstrap.argocd_server_secretkey
  accounts_pipeline_tokens = module.argocd_bootstrap.argocd_accounts_pipeline_tokens
  admin_enabled            = false
  exec_enabled             = true
  oidc = {
    name         = "OIDC"
    issuer       = module.oidc.oidc.issuer_url
    clientID     = module.oidc.oidc.client_id
    clientSecret = module.oidc.oidc.client_secret
    requestedIDTokenClaims = {
      groups = {
        essential = true
      }
    }
  }
  rbac = {
    policy_csv = <<-EOT
      g, pipeline, role:admin
      g, user, role:view
      g, modern-gitops-stack-admins, role:admin
    EOT
  }
  target_revision = local.target_revision
  dependency_ids = {
    traefik               = module.traefik.id
    cert-manager          = module.cert-manager.id
    oidc                  = module.oidc.id
    kube-prometheus-stack = module.kube-prometheus-stack.id
  }
}
