locals {
  oauth2_proxy_image       = "quay.io/oauth2-proxy/oauth2-proxy:v7.4.0"
  curl_wait_for_oidc_image = "curlimages/curl:8.1.1"

  helm_values = [{
    kube-prometheus-stack = {
      alertmanager = merge(local.alertmanager.enabled ? {
        alertmanagerSpec = {
          initContainers = [
            {
              name  = "wait-for-oidc"
              image = local.curl_wait_for_oidc_image
              command = [
                "/bin/sh",
                "-c",
              ]
              args = [
                <<-EOT
                until curl -skL -w "%%{http_code}\\n" "${replace(local.alertmanager.oidc.api_url, "\"", "\\\"")}" -o /dev/null | grep -vq "^\(000\|404\)$"; do echo "waiting for oidc at ${replace(local.alertmanager.oidc.api_url, "\"", "\\\"")}"; sleep 2; done
              EOT
              ]
            },
          ]
          containers = [
            {
              image = local.oauth2_proxy_image
              name  = "alertmanager-proxy"
              ports = [
                {
                  name          = "proxy"
                  containerPort = 9095
                },
              ]
              args = concat([
                "--http-address=0.0.0.0:9095",
                "--upstream=http://localhost:9093",
                "--provider=oidc",
                "--oidc-issuer-url=${replace(local.alertmanager.oidc.issuer_url, "\"", "\\\"")}",
                "--client-id=${replace(local.alertmanager.oidc.client_id, "\"", "\\\"")}",
                "--client-secret=${replace(local.alertmanager.oidc.client_secret, "\"", "\\\"")}",
                "--cookie-secure=false",
                "--cookie-secret=${replace(random_password.oauth2_cookie_secret.result, "\"", "\\\"")}",
                "--email-domain=*",
                "--redirect-url=https://${local.alertmanager.domain}/oauth2/callback",
              ], local.alertmanager.oidc.oauth2_proxy_extra_args)
            },
          ]
        }
        ingress = {
          enabled = true
          annotations = {
            "cert-manager.io/cluster-issuer"                   = "${var.cluster_issuer}"
            "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure"
            "traefik.ingress.kubernetes.io/router.middlewares" = "traefik-withclustername@kubernetescrd"
            "traefik.ingress.kubernetes.io/router.tls"         = "true"
            "ingress.kubernetes.io/ssl-redirect"               = "true"
            "kubernetes.io/ingress.allow-http"                 = "false"
          }
          servicePort = "9095"
          hosts = [
            "${local.alertmanager.domain}",
            "alertmanager.apps.${var.base_domain}"
          ]
          tls = [
            {
              secretName = "alertmanager-tls"
              hosts = [
                "${local.alertmanager.domain}",
                "alertmanager.apps.${var.base_domain}",
              ]
            },
          ]
        }
        service = {
          additionalPorts = [
            {
              name       = "proxy"
              port       = 9095
              targetPort = 9095
            },
          ]
        }
        } : null, {
        enabled = local.alertmanager.enabled
      })
      grafana = merge(local.grafana.enabled ? {
        adminPassword = "${replace(local.grafana.admin_password, "\"", "\\\"")}"
        "grafana.ini" = {
          "auth.generic_oauth" = merge({
            enabled                  = true
            allow_sign_up            = true
            client_id                = "${replace(local.grafana.oidc.client_id, "\"", "\\\"")}"
            client_secret            = "${replace(local.grafana.oidc.client_secret, "\"", "\\\"")}"
            scopes                   = "openid profile email"
            auth_url                 = "${replace(local.grafana.oidc.oauth_url, "\"", "\\\"")}"
            token_url                = "${replace(local.grafana.oidc.token_url, "\"", "\\\"")}"
            api_url                  = "${replace(local.grafana.oidc.api_url, "\"", "\\\"")}"
            tls_skip_verify_insecure = var.cluster_issuer == "ca-issuer" || var.cluster_issuer == "letsencrypt-staging"
          }, local.grafana.generic_oauth_extra_args)
          users = {
            auto_assign_org_role = "Editor"
          }
          server = {
            domain   = "${local.grafana.domain}"
            root_url = "https://%(domain)s" # TODO check this
          }
        }
        sidecar = {
          datasources = {
            defaultDatasourceEnabled = false
          }
        }
        additionalDataSources = [merge(var.metrics_storage_main != null ? {
          name = "Thanos"
          url  = "http://thanos-query.thanos:9090"
          } : {
          name = "Prometheus"
          url  = "http://kube-prometheus-stack-prometheus:9090"
          }, {
          type      = "prometheus"
          access    = "proxy"
          isDefault = true
          jsonData = {
            tlsAuth           = false
            tlsAuthWithCACert = false
            oauthPassThru     = true
          }
          }
        )]
        ingress = {
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
            "${local.grafana.domain}",
            "grafana.apps.${var.base_domain}",
          ]
          tls = [
            {
              secretName = "grafana-tls"
              hosts = [
                "${local.grafana.domain}",
                "grafana.apps.${var.base_domain}",
              ]
            },
          ]
        }
        } : null,
        merge((!local.grafana.enabled && local.grafana.additional_data_sources) ? {
          forceDeployDashboards  = true
          forceDeployDatasources = true
          sidecar = {
            datasources = {
              defaultDatasourceEnabled = false
            }
          }
          additionalDataSources = [merge(var.metrics_storage_main != null ? {
            name = "Thanos"
            url  = "http://thanos-query.thanos:9090"
            } : {
            # Note that since this is for the the Grafana module deployed inside it's
            # own namespace, we need to have the reference to the namespace in the URL.
            name = "Prometheus"
            url  = "http://kube-prometheus-stack-prometheus.kube-prometheus-stack:9090"
            }, {
            type      = "prometheus"
            access    = "proxy"
            isDefault = true
            jsonData = {
              tlsAuth           = false
              tlsAuthWithCACert = false
              oauthPassThru     = true
            }
            }
          )]
          } : null, {
          enabled = local.grafana.enabled
        })
      )
      prometheus = merge(local.prometheus.enabled ? {
        ingress = {
          enabled = true
          annotations = {
            "cert-manager.io/cluster-issuer"                   = "${var.cluster_issuer}"
            "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure"
            "traefik.ingress.kubernetes.io/router.middlewares" = "traefik-withclustername@kubernetescrd"
            "traefik.ingress.kubernetes.io/router.tls"         = "true"
            "ingress.kubernetes.io/ssl-redirect"               = "true"
            "kubernetes.io/ingress.allow-http"                 = "false"
          }
          servicePort = "9091"
          hosts = [
            "${local.prometheus.domain}",
            "prometheus.apps.${var.base_domain}",
          ]
          tls = [
            {
              secretName = "prometheus-tls"
              hosts = [
                "${local.prometheus.domain}",
                "prometheus.apps.${var.base_domain}",
              ]
            },
          ]
        }
        prometheusSpec = merge({
          initContainers = [
            {
              name  = "wait-for-oidc"
              image = local.curl_wait_for_oidc_image
              command = [
                "/bin/sh",
                "-c",
              ]
              args = [
                <<-EOT
                until curl -skL -w "%%{http_code}\\n" "${replace(local.prometheus.oidc.api_url, "\"", "\\\"")}" -o /dev/null | grep -vq "^\(000\|404\)$"; do echo "waiting for oidc at ${replace(local.prometheus.oidc.api_url, "\"", "\\\"")}"; sleep 2; done
              EOT
              ]
            },
          ]
          containers = [
            {
              args = concat([
                "--http-address=0.0.0.0:9091",
                "--upstream=http://localhost:9090",
                "--provider=oidc",
                "--oidc-issuer-url=${replace(local.prometheus.oidc.issuer_url, "\"", "\\\"")}",
                "--client-id=${replace(local.prometheus.oidc.client_id, "\"", "\\\"")}",
                "--client-secret=${replace(local.prometheus.oidc.client_secret, "\"", "\\\"")}",
                "--cookie-secure=false",
                "--cookie-secret=${replace(random_password.oauth2_cookie_secret.result, "\"", "\\\"")}",
                "--email-domain=*",
                "--redirect-url=https://${local.prometheus.domain}/oauth2/callback",
              ], local.prometheus.oidc.oauth2_proxy_extra_args)
              image = local.oauth2_proxy_image
              name  = "prometheus-proxy"
              ports = [
                {
                  containerPort = 9091
                  name          = "proxy"
                },
              ]
            },
          ]
          alertingEndpoints = [
            {
              name      = "kube-prometheus-stack-alertmanager"
              namespace = "kube-prometheus-stack"
              port      = 9093
            },
          ]
          externalLabels = {
            prometheus = "prometheus-${var.cluster_name}"
          }
          }, var.metrics_storage_main != null ? {
          thanos = {
            objectStorageConfig = {
              key  = "thanos.yaml"
              name = "thanos-objectstorage"
            }
          }
        } : null)
        service = {
          additionalPorts = [
            {
              name       = "proxy"
              port       = 9091
              targetPort = 9091
            },
          ]
        }
        } : null, {
        enabled = local.prometheus.enabled
        thanosService = {
          enabled = var.metrics_storage_main != null ? true : false
        }
        }
      )
    }
  }]

  grafana_defaults = {
    enabled                  = true
    additional_data_sources  = false
    generic_oauth_extra_args = {}
    domain                   = "grafana.apps.${var.cluster_name}.${var.base_domain}"
    admin_password           = random_password.grafana_admin_password.result
  }

  grafana = merge(
    local.grafana_defaults,
    var.grafana,
  )

  prometheus_defaults = {
    enabled = true
    domain  = "prometheus.apps.${var.cluster_name}.${var.base_domain}"
  }

  prometheus = merge(
    local.prometheus_defaults,
    var.prometheus,
  )

  alertmanager_defaults = {
    enabled = true
    domain  = "alertmanager.apps.${var.cluster_name}.${var.base_domain}"
  }

  alertmanager = merge(
    local.alertmanager_defaults,
    var.alertmanager,
  )
}

resource "random_password" "grafana_admin_password" {
  length  = 16
  special = false
}