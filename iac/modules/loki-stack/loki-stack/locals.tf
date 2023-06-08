locals {
  fullnameOverride = "loki"

  helm_values = [
    {
      eventHandler = {
        namespace       = var.namespace
        lokiURL         = var.distributed_mode ? "http://${local.fullnameOverride}-distributor.${var.namespace}:3100/loki/api/v1/push" : "http://${local.fullnameOverride}.${var.namespace}:3100/loki/api/v1/push"
        labels          = {}
        grafanaAgentTag = "main-4f86002"
      }
    },
    {
      frontendIngress = var.ingress != null ? {
        lokiCredentials = base64encode("loki:${htpasswd_password.loki_password_hash.0.bcrypt}")
        hosts           = var.ingress.hosts
        clusterIssuer   = var.ingress.cluster_issuer
        allowedIPs      = var.ingress.allowed_ips
        serviceName     = "${local.fullnameOverride}-query-frontend"
      } : null
    },
    var.distributed_mode ? merge({
      datasourceURL = "http://${local.fullnameOverride}-query-frontend.${var.namespace}:3100"
      loki-distributed = {
        fullnameOverride = local.fullnameOverride
        compactor = {
          enabled = true
          persistence = {
            enabled = true
          }
        }
        gateway = {
          enabled = false
        }
        indexGateway = {
          enabled = true
          persistence = {
            enabled = true
          }
        }
        # TODO ingester HA
        ingester = {
          persistence = {
            enabled = true
          }
          replicas = 1
        }
        loki = {
          structuredConfig = {
            common = {
              compactor_address = "http://${local.fullnameOverride}-compactor:3100"
            }
            ruler = {
              alertmanager_url = "http://kube-prometheus-stack-alertmanager.kube-prometheus-stack:9093"
            }
            chunk_store_config = {
              chunk_cache_config = {
                memcached = {
                  expiration = "24h"
                }
                memcached_client = {
                  service = "memcached-client"
                  timeout = "500ms"
                }
              }
            }
            compactor = {
              retention_delete_delay = "1h"
              retention_enabled      = false
            }
            ingester = {
              wal = {
                replay_memory_ceiling = "500MB"
                flush_on_shutdown     = true
              }
            }
            limits_config = {
              ingestion_rate_mb           = 10
              max_chunks_per_query        = 0
              max_entries_limit_per_query = 0
              max_query_length            = "9000h"
              max_query_parallelism       = 6
              per_stream_rate_limit       = "10MB"
              retention_period            = "9000h"
            }
            querier = {
              max_concurrent = 4
              query_timeout  = "5m"
            }
            query_range = {
              cache_results                 = true
              max_retries                   = 50
              parallelise_shardable_queries = false
              results_cache = {
                cache = {
                  memcached = {
                    expiration = "24h"
                  }
                  memcached_client = {
                    service = "memcached-client"
                    timeout = "500ms"
                  }
                }
              }
            }
            server = {
              grpc_server_max_recv_msg_size = 33554432
              grpc_server_max_send_msg_size = 33554432
              http_server_read_timeout      = "180s"
              http_server_write_timeout     = "180s"
            }
            storage_config = {
              boltdb_shipper = {
                index_gateway_client = {
                  log_gateway_requests = true
                }
              }
              index_queries_cache_config = {
                memcached = {
                  expiration = "24h"
                }
                memcached_client = {
                  service = "memcached-client"
                  timeout = "500ms"
                }
              }
            }
          }
        }
        memcachedChunks = {
          enabled = true
        }
        memcachedFrontend = {
          enabled = true
        }
        memcachedIndexQueries = {
          enabled = true
        }
        queryScheduler = {
          enabled  = true
          affinity = ""
        }
        querier = {
          affinity       = ""
          replicas       = 4
          maxUnavailable = 4
        }
        ruler = {
          directories = {}
          enabled     = false
        }
      }
      promtail = {
        config = {
          clients = [{
            url = "http://${local.fullnameOverride}-distributor.${var.namespace}:3100/loki/api/v1/push"
          }]
        }
      }
      }, {
      filebeat = {
        enabled         = var.enable_filebeat
        extraContainers = <<-EOT
        - name: filebeat-prometheus-exporter
          image: "trustpilot/beat-exporter:0.4.0"
          ports:
            - containerPort: 9479
              protocol: TCP
              name: metrics
        EOT
      }
    }) : null,
    var.distributed_mode ? null : {
      loki-stack = {
        loki = {
          fullnameOverride = local.fullnameOverride
          serviceName      = "${local.fullnameOverride}.${var.namespace}"
          # TODO serviceMonitor is a KPS CRD, manage this circular dependency
          serviceMonitor = {
            enabled = true
          }
          isDefault = false
        }
        promtail = {
          config = {
            clients = [
              {
                url = "http://${local.fullnameOverride}:3100/loki/api/v1/push"
              }
            ]
          }
          # Same previous comment
          serviceMonitor = {
            enabled = true
          }
          # TODO check next block's indentation
          # TODO check possible factorization of the following block, also added to Loki µsvcy
          filebeat = {
            extraContainers = <<-EOT
          - name: filebeat-prometheus-exporter
            image: "trustpilot/beat-exporter:0.4.0"
            ports:
            - containerPort: 9479
              protocol: TCP
              name: metrics
        EOT
          }
        }
      }
    }
  ]
}