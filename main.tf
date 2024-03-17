module "kind" {
  source = "./modules/kind"

  cluster_name       = local.cluster_name
  kubernetes_version = local.kubernetes_version
}

module "metallb" {
  source = "./modules/metallb"

  subnet = module.kind.kind_subnet
}

module "argocd_bootstrap" {
  source = "./modules/argocd_bootstrap"

  argocd_projects = {
    "${local.cluster_name}" = {
      destination_cluster = "in-cluster"
    }
  }

  depends_on = [module.kind]
}

module "metrics-server" {
  source = "./modules/metrics-server"

  argocd_project = local.cluster_name

  app_autosync = local.app_autosync

  kubelet_insecure_tls = true

  argocd_namespace    = module.argocd_bootstrap.argocd_namespace
  target_revision     = local.target_revision
  project_source_repo = local.project_source_repo

  dependency_ids = {
    argocd = module.argocd_bootstrap.id
  }
}

module "traefik" {
  source = "./modules/traefik/kind"

  argocd_project = local.cluster_name

  app_autosync           = local.app_autosync
  enable_service_monitor = local.enable_service_monitor

  argocd_namespace    = module.argocd_bootstrap.argocd_namespace
  target_revision     = local.target_revision
  project_source_repo = local.project_source_repo

  dependency_ids = {
    argocd = module.argocd_bootstrap.id
  }
}

module "cert-manager" {
  source = "./modules/cert-manager/self-signed"

  argocd_project = local.cluster_name

  app_autosync           = local.app_autosync
  enable_service_monitor = local.enable_service_monitor

  argocd_namespace    = module.argocd_bootstrap.argocd_namespace
  target_revision     = local.target_revision
  project_source_repo = local.project_source_repo

  dependency_ids = {
    argocd = module.argocd_bootstrap.id
  }
}

module "keycloak" {
  source = "./modules/keycloak"

  cluster_name   = local.cluster_name
  base_domain    = local.base_domain
  subdomain      = local.subdomain
  cluster_issuer = local.cluster_issuer
  argocd_project = local.cluster_name

  app_autosync = local.app_autosync

  argocd_namespace    = module.argocd_bootstrap.argocd_namespace
  target_revision     = local.target_revision
  project_source_repo = local.project_source_repo

  dependency_ids = {
    traefik      = module.traefik.id
    cert-manager = module.cert-manager.id
  }
}

module "oidc" {
  source = "./modules/oidc"

  cluster_name   = local.cluster_name
  base_domain    = local.base_domain
  subdomain      = local.subdomain
  cluster_issuer = local.cluster_issuer

  user_map = {
    YOUR_USERNAME = {
      username   = "gersonrs"
      email      = "gersonrs@live.com"
      first_name = "gerson"
      last_name  = "santos"
    },
  }

  dependency_ids = {
    keycloak = module.keycloak.id
  }
}

module "minio" {
  source = "./modules/minio"

  cluster_name   = local.cluster_name
  base_domain    = local.base_domain
  subdomain      = local.subdomain
  cluster_issuer = local.cluster_issuer
  argocd_project = local.cluster_name

  app_autosync           = local.app_autosync
  enable_service_monitor = local.enable_service_monitor

  config_minio = local.minio_config

  oidc = module.oidc.oidc

  argocd_namespace    = module.argocd_bootstrap.argocd_namespace
  target_revision     = local.target_revision
  project_source_repo = local.project_source_repo

  dependency_ids = {
    traefik      = module.traefik.id
    cert-manager = module.cert-manager.id
    oidc         = module.oidc.id
  }
}

module "loki-stack" {
  source = "./modules/loki-stack/kind"

  argocd_project = local.cluster_name

  app_autosync = local.app_autosync

  logs_storage = {
    bucket_name = local.minio_config.buckets.0.name
    endpoint    = module.minio.endpoint
    access_key  = local.minio_config.users.0.accessKey
    secret_key  = local.minio_config.users.0.secretKey
  }

  argocd_namespace    = module.argocd_bootstrap.argocd_namespace
  target_revision     = local.target_revision
  project_source_repo = local.project_source_repo

  dependency_ids = {
    minio = module.minio.id
  }
}

module "thanos" {
  source = "./modules/thanos/kind"

  cluster_name   = local.cluster_name
  base_domain    = local.base_domain
  subdomain      = local.subdomain
  cluster_issuer = local.cluster_issuer
  argocd_project = local.cluster_name

  app_autosync = local.app_autosync

  enable_service_monitor = local.enable_service_monitor

  metrics_storage = {
    bucket_name = local.minio_config.buckets.1.name
    endpoint    = module.minio.endpoint
    access_key  = local.minio_config.users.1.accessKey
    secret_key  = local.minio_config.users.1.secretKey
  }

  thanos = {
    oidc = module.oidc.oidc
  }

  argocd_namespace    = module.argocd_bootstrap.argocd_namespace
  target_revision     = local.target_revision
  project_source_repo = local.project_source_repo

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
  source = "./modules/kube-prometheus-stack/kind"

  cluster_name   = local.cluster_name
  base_domain    = local.base_domain
  subdomain      = local.subdomain
  cluster_issuer = local.cluster_issuer
  argocd_project = local.cluster_name

  app_autosync = local.app_autosync

  metrics_storage_main = {
    bucket_name = local.minio_config.buckets.1.name
    endpoint    = module.minio.endpoint
    access_key  = local.minio_config.users.1.accessKey
    secret_key  = local.minio_config.users.1.secretKey
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

  argocd_namespace    = module.argocd_bootstrap.argocd_namespace
  target_revision     = local.target_revision
  project_source_repo = local.project_source_repo

  dependency_ids = {
    traefik      = module.traefik.id
    cert-manager = module.cert-manager.id
    minio        = module.minio.id
    oidc         = module.oidc.id
  }
}

module "argocd" {
  source = "./modules/argocd"

  base_domain              = local.base_domain
  cluster_name             = local.cluster_name
  subdomain                = local.subdomain
  cluster_issuer           = local.cluster_issuer
  server_secretkey         = module.argocd_bootstrap.argocd_server_secretkey
  accounts_pipeline_tokens = module.argocd_bootstrap.argocd_accounts_pipeline_tokens
  argocd_project           = local.cluster_name

  app_autosync = local.app_autosync

  admin_enabled = false
  exec_enabled  = true

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
      g, modern-gitops-stack-admins, role:admin
    EOT
  }

  argocd_namespace    = module.argocd_bootstrap.argocd_namespace
  target_revision     = local.target_revision
  project_source_repo = local.project_source_repo

  dependency_ids = {
    traefik               = module.traefik.id
    cert-manager          = module.cert-manager.id
    oidc                  = module.oidc.id
    kube-prometheus-stack = module.kube-prometheus-stack.id
  }
}
