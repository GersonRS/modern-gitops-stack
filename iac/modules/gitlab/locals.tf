locals {
  helm_values = [{
    global = {
      appConfig = {
        omniauth = {
          enabled                 = true
          autoSignInWithProvider  = ["openid_connect"]
          syncProfileFromProvider = ["openid_connect"]
          syncProfileAttributes   = ["email"]
          allowSingleSignOn       = ["openid_connect"]
          blockAutoCreatedUsers   = false
          autoLinkLdapUser        = false
          autoLinkSamlUser        = false
          autoLinkUser            = ["openid_connect"]
          externalProviders       = []
          allowBypassTwoFactor    = ["openid_connect"]

          providers = [{
            name  = "openid_connect", 
            label = "Keycloak",       
            args = {
              name               = "openid_connect",
              scope              = ["openid", "profile", "email"],
              response_type      = "code",
              issuer             = var.oidc.issuer_url,
              client_auth_method = "query",
              discovery          = true,
              uid_field          = "uid",
              client_options = {
                identifier             = var.oidc.client_id,
                secret                 = var.oidc.client_secret,
                redirect_uri           = "http://gitlab.${var.cluster_name}.${var.base_domain}/users/auth/openid_connect/callback"
                authorization_endpoint = var.oidc.oauth_url,
                token_endpoint         = var.oidc.token_url,
                userinfo_endpoint      = var.oidc.api_url,
              }
            }
          }]
        }
      }
      ingress = {
        configureCertmanager = false,
        class : "traefik",
        annotations = {
          "cert-manager.io/cluster-issuer"                   = "${var.cluster_issuer}"
          "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure"
          "traefik.ingress.kubernetes.io/router.middlewares" = "traefik-withclustername@kubernetescrd"
          "traefik.ingress.kubernetes.io/router.tls"         = "true"
          "ingress.kubernetes.io/ssl-redirect"               = "true"
          "kubernetes.io/ingress.allow-http"                 = "false"
        },
        tls = [{
          enabled = true
          secretName = "gitlab-tls",
          hosts = [
            "gitlab.${var.base_domain}",
            "gitlab.${var.cluster_name}.${var.base_domain}",
          ]
        }]
      }
      hosts = {
        domain     = "gitlab.${var.base_domain}",
        externalIP = "gitlab.${var.cluster_name}.${var.base_domain}",
      }
      rails = {
        bootsnap = {
          enabled = false
        }
      }
      shell = {
        port = 32022
      }
    }
    certmanager = {
      install = false
    }
    nginx-ingress = {
      enabled = false
    }
    prometheus = {
      install = false
    }
    gitlab-runner = {
      install = false
    }
    gitlab = {
      webservice = {
        minReplicas = 1
        maxReplicas = 1
      }
      sidekiq = {
        minReplicas = 1
        maxReplicas = 1
      }
      gitlab-shell = {
        minReplicas = 1
        maxReplicas = 1
        service = {
          type = "NodePort"
          nodePort = 32022
        }
      }
    }
    registry = {
      hpa = {
        minReplicas = 1
        maxReplicas = 1
      }
    }
  }]
}
