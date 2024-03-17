locals {
  helm_values = [{
    traefik = {
      deployment = {
        replicas = var.replicas
      }
      metrics = {
        prometheus = {
          service = {
            enabled = true
          }
          serviceMonitor = var.enable_service_monitor ? {
            # Dummy attribute to make serviceMonitor evaluate to true in a condition in the Helm chart
            foo = "bar"
          } : {}
        }
      }
      additionalArguments = [
        "--serversTransport.insecureSkipVerify=true"
      ]
      logs = {
        access = {
          enabled = true
        }
      }
      tlsOptions = {
        default = {
          minVersion = "VersionTLS12"
        }
      }
      ports = var.enable_https_redirection ? {
        web = {
          redirectTo = {
            port = "websecure"
          }
        }
      } : null
      ressources = { # TODO: use var.resources instead and fix the typo in "reSSources"
        limits = {
          cpu    = "250m"
          memory = "512Mi"
        }
        requests = {
          cpu    = "125m"
          memory = "256Mi"
        }
      }
    }
  }]
}
