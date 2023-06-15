locals {
  provider = [{
    # name  = "openid_connect"
    # label = "openid_connect"
    # args = {
    #   name               = "openid_connect"
    #   scope              = ["openid", "profile", "email"]
    #   response_type      = "code"
    #   issuer             = var.oidc.issuer_url
    #   client_auth_method = "query"
    #   discovery          = true
    #   uid_field          = "preferred_username",
    #   client_options = {
    #     port                   = 443
    #     scheme                 = "https"
    #     identifier             = var.oidc.client_id
    #     secret                 = var.oidc.client_secret
    #     redirect_uri           = "http://gitlab.${var.cluster_name}.${var.base_domain}/users/auth/openid_connect/callback"
    #     # authorization_endpoint = var.oidc.oauth_url
    #     # token_endpoint         = var.oidc.token_url
    #     # userinfo_endpoint      = var.oidc.api_url
    #   }
    # }
    name       = "oauth2_generic"
    # label      = "Provider name" # optional label for login button defaults to "Oauth2 Generic"
    app_id     = var.oidc.client_id
    app_secret = var.oidc.client_secret
    args = {
      client_options = {
        site          = var.oidc.issuer_url
        user_info_url = "/realms/modern-devops-stack/protocol/openid-connect/userinfo"
        authorize_url = "/realms/modern-devops-stack/protocol/openid-connect/auth"
        token_url     = "/realms/modern-devops-stack/protocol/openid-connect/token"
      }
      user_response_structure = {
        root_path: ["data", "user"],
        # id_path   = ["sub"]
        attributes = {
          email = "email"
          name  = "name"
        }
      }
      # redirect_uri = "https://gitlab.${var.cluster_name}.${var.base_domain}/users/auth/oauth2_generic/callback"
      authorize_params = {
        scope = "openid profile email"
      }
      strategy_class = "OmniAuth::Strategies::OAuth2Generic"
    }
  }]

  helm_values = [{
    global = {
      appConfig = {
        omniauth = {
          enabled                 = true
          allowSingleSignOn       = ["oauth2_generic"]
          blockAutoCreatedUsers   = false

          providers = [{
            secret = "gitlab-provider"
          }]
        }
      }

      ingress = {
        configureCertmanager = false
        class = "traefik"
        provider = "traefik"
        annotations = {
          "cert-manager.io/cluster-issuer"                   = "${var.cluster_issuer}"
          "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure"
          "traefik.ingress.kubernetes.io/router.middlewares" = "traefik-withclustername@kubernetescrd"
          "traefik.ingress.kubernetes.io/router.tls"         = "true"
          "ingress.kubernetes.io/ssl-redirect"               = "true"
          "kubernetes.io/ingress.allow-http"                 = "false"
        }
      }
      hosts = {
        domain     = "apps.${var.cluster_name}.${var.base_domain}"
        externalIP = replace(split(".", var.base_domain)[0], "-", ".")
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
    certmanager-issuer = {
      email = "gersonrs@live.com"
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
          type     = "NodePort"
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

# helm upgrade --install gitlab gitlab/gitlab \
#    --timeout 600s   \
#    -f values.yaml
#    -f https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-traefik-ingress.yaml \
#    --set global.hosts.domain=apps.kind.172-18-0-100.nip.io \
#    --set global.hosts.externalIP=172.18.0.100 \
#    --set certmanager-issuer.email="gersonrs@live.com" \
#    --set global.appConfig.omniauth.enabled=true \
#    --set global.appConfig.omniauth.allowSingleSignOn=["oauth2_generic"] \
#    --set global.appConfig.omniauth.blockAutoCreatedUsers=true
#    --set global.appConfig.omniauth.autoLinkLdapUser=false
#    --set global.appConfig.omniauth.providers=[{secret = "gitlab-oauth2-generic"}]