locals {
  oauth2_proxy_image = "quay.io/oauth2-proxy/oauth2-proxy:v7.5.0"

  ingress_annotations = {
    "cert-manager.io/cluster-issuer"                   = "${var.cluster_issuer}"
    "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure"
    "traefik.ingress.kubernetes.io/router.tls"         = "true"
  }

  # values.yaml translated into HCL structures.
  # Possible values available here -> https://github.com/bitnami/charts/tree/master/bitnami/thanos/
  helm_values = [{
    redis = {
      architecture = "standalone"
      auth = {
        enabled  = true
        password = random_password.redis_password.result
      }
      master = {
        persistence = {
          enabled = false
        }
      }
    }
    thanos = {
      metrics = {
        enabled = true
        serviceMonitor = {
          enabled = var.enable_service_monitor
        }
      }

      storegateway = {
        enabled = true
        persistence = {
          enabled = false
        }
        resources = local.thanos.storegateway_resources
        networkPolicy = {
          enabled = false
        }
        extraFlags = [
          # Store Gateway index cache config -> https://thanos.io/tip/components/store.md/#index-cache
          <<-EOT
          --index-cache.config="config":
            addr: "thanos-redis-master:6379"
            password: ${random_password.redis_password.result}
            db: 0
            dial_timeout: 5s
            read_timeout: 3s
            write_timeout: 3s
            max_get_multi_concurrency: 1000
            get_multi_batch_size: 100
            max_set_multi_concurrency: 1000
            set_multi_batch_size: 100
            tls_enabled: false
            cache_size: 0
            max_async_buffer_size: 1000000
            max_async_concurrency: 200
            expiration: 2h
          "type": "REDIS"
          EOT
        ]
      }

      query = {
        dnsDiscovery = {
          enabled           = true
          sidecarsService   = "kube-prometheus-stack-thanos-discovery" # Name of the service that exposes thanos-sidecar
          sidecarsNamespace = "kube-prometheus-stack"
        }
        stores = [
          "thanos-storegateway:10901"
        ]
        resources = local.thanos.query_resources
        networkPolicy = {
          enabled = false
        }
      }

      compactor = {
        enabled                = true
        retentionResolutionRaw = "${local.thanos.compactor_retention.raw}"
        retentionResolution5m  = "${local.thanos.compactor_retention.five_min}"
        retentionResolution1h  = "${local.thanos.compactor_retention.one_hour}"
        resources              = local.thanos.compactor_resources
        persistence = {
          # The Access Mode needs to be set as ReadWriteOnce because AWS Elastic Block storage does not support other
          # modes (https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes).
          # Since the compactor is the only pod accessing this volume, there should be no issue to have this as
          # ReadWriteOnce (https://stackoverflow.com/a/57799347).
          accessModes = [
            "ReadWriteOnce"
          ]
          size = local.thanos.compactor_persistence_size
        }
        networkPolicy = {
          enabled = false
        }
      }

      bucketweb = {
        enabled = true
        sidecars = [{
          args = concat([
            "--http-address=0.0.0.0:9075",
            "--upstream=http://localhost:8080",
            "--provider=oidc",
            "--oidc-issuer-url=${replace(local.thanos.oidc.issuer_url, "\"", "\\\"")}",
            "--client-id=${replace(local.thanos.oidc.client_id, "\"", "\\\"")}",
            "--client-secret=${replace(local.thanos.oidc.client_secret, "\"", "\\\"")}",
            "--cookie-secure=false",
            "--cookie-secret=${replace(random_password.oauth2_cookie_secret.result, "\"", "\\\"")}",
            "--email-domain=*",
            "--redirect-url=https://${local.thanos.bucketweb_domain}/oauth2/callback",
          ], local.thanos.oidc.oauth2_proxy_extra_args)
          image = local.oauth2_proxy_image
          name  = "thanos-proxy"
          ports = [{
            containerPort = 9075
            name          = "proxy"
          }]
        }]
        service = {
          extraPorts = [{
            name       = "proxy"
            port       = 9075
            protocol   = "TCP"
            targetPort = "proxy"
          }]
        }
        ingress = {
          enabled     = true
          annotations = local.ingress_annotations
          tls         = false
          hostname    = ""
          extraRules = [
            {
              host = "thanos-bucketweb.${trimprefix("${var.subdomain}.${var.base_domain}", ".")}"
              http = {
                paths = [
                  {
                    backend = {
                      service = {
                        name = "thanos-bucketweb"
                        port = {
                          name = "proxy"
                        }
                      }
                    }
                    path     = "/"
                    pathType = "ImplementationSpecific"
                  }
                ]
              }
            },
            {
              host = "${local.thanos.bucketweb_domain}"
              http = {
                paths = [
                  {
                    backend = {
                      service = {
                        name = "thanos-bucketweb"
                        port = {
                          name = "proxy"
                        }
                      }
                    }
                    path     = "/"
                    pathType = "ImplementationSpecific"
                  }
                ]
              }
            },
          ]
          extraTls = [{
            secretName = "thanos-bucketweb-tls"
            hosts = [
              "thanos-bucketweb.${trimprefix("${var.subdomain}.${var.base_domain}", ".")}",
              "${local.thanos.bucketweb_domain}"
            ]
          }]
        }
        networkPolicy = {
          enabled = false
        }
      }

      queryFrontend = {
        extraFlags = [
          # Query Frontend response cache config -> https://thanos.io/tip/components/query-frontend.md/#caching
          <<-EOT
          --query-range.response-cache-config="config":
            addr: "thanos-redis-master:6379"
            password: ${random_password.redis_password.result}
            db: 1
            dial_timeout: 5s
            read_timeout: 3s
            write_timeout: 3s
            max_get_multi_concurrency: 1000
            get_multi_batch_size: 100
            max_set_multi_concurrency: 1000
            set_multi_batch_size: 100
            tls_enabled: false
            cache_size: 0
            max_async_buffer_size: 1000000
            max_async_concurrency: 200
            expiration: 2h
          "type": "REDIS"   
          EOT
          ,
          <<-EOT
          --labels.response-cache-config="config":
            addr: "thanos-redis-master:6379"
            password: ${random_password.redis_password.result}
            db: 2
            dial_timeout: 5s
            read_timeout: 3s
            write_timeout: 3s
            max_get_multi_concurrency: 1000
            get_multi_batch_size: 100
            max_set_multi_concurrency: 1000
            set_multi_batch_size: 100
            tls_enabled: false
            cache_size: 0
            max_async_buffer_size: 1000000
            max_async_concurrency: 200
            expiration: 2h
          "type": "REDIS"   
          EOT
          ,
        ]
        sidecars = [{
          args = concat([
            "--http-address=0.0.0.0:9075",
            "--upstream=http://localhost:9090",
            "--provider=oidc",
            "--oidc-issuer-url=${replace(local.thanos.oidc.issuer_url, "\"", "\\\"")}",
            "--client-id=${replace(local.thanos.oidc.client_id, "\"", "\\\"")}",
            "--client-secret=${replace(local.thanos.oidc.client_secret, "\"", "\\\"")}",
            "--cookie-secure=false",
            "--cookie-secret=${replace(random_password.oauth2_cookie_secret.result, "\"", "\\\"")}",
            "--email-domain=*",
            "--redirect-url=https://${local.thanos.query_domain}/oauth2/callback",
          ], local.thanos.oidc.oauth2_proxy_extra_args)
          image = local.oauth2_proxy_image
          name  = "thanos-proxy"
          ports = [{
            containerPort = 9075
            name          = "proxy"
          }]
        }]
        service = {
          extraPorts = [{
            name       = "proxy"
            port       = 9075
            protocol   = "TCP"
            targetPort = "proxy"
          }]
        }
        ingress = {
          enabled     = true
          annotations = local.ingress_annotations
          tls         = false
          hostname    = ""
          extraRules = [
            {
              host = "thanos-query.${trimprefix("${var.subdomain}.${var.base_domain}", ".")}"
              http = {
                paths = [
                  {
                    backend = {
                      service = {
                        name = "thanos-query-frontend"
                        port = {
                          name = "proxy"
                        }
                      }
                    }
                    path     = "/"
                    pathType = "ImplementationSpecific"
                  }
                ]
              }
            },
            {
              host = "${local.thanos.query_domain}"
              http = {
                paths = [
                  {
                    backend = {
                      service = {
                        name = "thanos-query-frontend"
                        port = {
                          name = "proxy"
                        }
                      }
                    }
                    path     = "/"
                    pathType = "ImplementationSpecific"
                  }
                ]
              }
            },
          ]
          extraTls = [{
            secretName = "thanos-query-tls"
            hosts = [
              "thanos-query.${trimprefix("${var.subdomain}.${var.base_domain}", ".")}",
              "${local.thanos.query_domain}"
            ]
          }]
        }
        networkPolicy = {
          enabled = false
        }
      }
      receive = {
        networkPolicy = {
          enabled = false
        }
      }
      ruler = {
        networkPolicy = {
          enabled = false
        }
      }
    }
  }]

  thanos_defaults = {
    query_domain     = "thanos-query.${trimprefix("${var.subdomain}.${var.cluster_name}", ".")}.${var.base_domain}"
    bucketweb_domain = "thanos-bucketweb.${trimprefix("${var.subdomain}.${var.cluster_name}", ".")}.${var.base_domain}"

    # TODO Create proper Terraform variables for these values instead of bundling everything inside of these locals

    # This is the size for the PersistentVolume used by the Thanos Compactor to perform its operations.
    # By default, it is set at 8Gi but the documentation recommends a size of 100-300Gi.
    # We left the default value at 8Gi only to have a working configuration, but this value MUST be configured otherwise
    # the compactor will NOT work on a production deployment. The size of this PV cannot be changed afterwards.
    compactor_persistence_size = "8Gi"

    compactor_retention = {
      raw      = "60d"
      five_min = "120d"
      one_hour = "240d"
    }

    # TODO Create flavors instead of needing to pass resources values like this
    compactor_resources = {
      limits = {
        memory = "1Gi"
      }
    }
    storegateway_resources = {
      limits = {
        memory = "1Gi"
      }
    }
    query_resources = {
      limits = {
        memory = "1Gi"
      }
    }
  }

  thanos = merge(
    local.thanos_defaults,
    var.thanos,
  )
}
