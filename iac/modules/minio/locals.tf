locals {
  self_signed_cert_enabled = var.cluster_issuer == "ca-issuer" || var.cluster_issuer == "letsencrypt-staging"

  self_signed_cert = {
    extraVolumeMounts = [
      {
        name      = "certificate"
        mountPath = "/etc/ssl/certs/ca.crt"
        subPath   = "ca.crt"
      },
    ]
    extraVolumes = [
      {
        name = "certificate"
        secret = {
          secretName = "minio-tls"
        }
      }
    ]
  }

  oidc_config = merge(
    {
      oidc = {
        enabled      = var.oidc.issuer_url != "" && var.oidc.client_id != "" && var.oidc.client_secret != ""
        configUrl    = "${var.oidc.issuer_url}/.well-known/openid-configuration"
        clientId     = var.oidc.client_id
        clientSecret = var.oidc.client_secret
        claimName    = "policy"
        scopes       = "openid,profile,email"
        redirectUri  = "https://minio.apps.${var.cluster_name}.${var.base_domain}/oauth_callback"
        claimPrefix  = ""
        comment      = ""
      }
    },
    local.self_signed_cert_enabled ? local.self_signed_cert : null
  )

  helm_values = [{
    minio = merge(
      {
        mode = "standalone" # Set the deployment mode of MinIO to standalone
        resources = {
          requests = {
            memory = "128Mi"
          }
        }
        consoleIngress = {
          enabled = true
          annotations = {
            "cert-manager.io/cluster-issuer"                   = "${var.cluster_issuer}"
            "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure"
            "traefik.ingress.kubernetes.io/router.middlewares" = "traefik-withclustername@kubernetescrd"
            "traefik.ingress.kubernetes.io/router.tls"         = "true"
            "ingress.kubernetes.io/ssl-redirect"               = "true"
            "kubernetes.io/ingress.allow-http"                 = "false"
          }
          hosts = [
            "minio.apps.${var.base_domain}",
            "minio.apps.${var.cluster_name}.${var.base_domain}",
          ]
          tls = [{
            secretName = "minio-tls"
            hosts = [
              "minio.apps.${var.base_domain}",
              "minio.apps.${var.cluster_name}.${var.base_domain}",
            ]
          }]
        }
        metrics = {
          serviceMonitor = {
            enabled = var.enable_service_monitor
          }
        }
        rootUser     = "root"
        rootPassword = random_password.minio_root_secretkey.result
        users        = var.config_minio.users
        buckets      = var.config_minio.buckets
        policies     = var.config_minio.policies
      },
      local.oidc_config.oidc.enabled ? local.oidc_config : null
    )
  }]
}