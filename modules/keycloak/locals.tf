locals {
  helm_values = [{
    keycloak = {
      name = "keycloak"
      # Database creds are shown in tfm plan.
      # TODO manage this. Proposal: create namespace and secret before app.
      database = var.database != null ? merge(var.database, {
        create   = false
        username = base64encode(var.database.username)
        password = base64encode(var.database.password)
        }) : {
        # TODO doc that the fallback map (experimental ephemeral postgresql server) should never be used in production.
        create   = true
        vendor   = "postgres"
        username = base64encode("postgres")
        password = base64encode(random_password.db_password.0.result)
        host     = "keycloak-postgres-db"
      }
      ingress = {
        enabled = true
        annotations = {
          "cert-manager.io/cluster-issuer"                   = "${var.cluster_issuer}"
          "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure"
          "traefik.ingress.kubernetes.io/router.tls"         = "true"
        }
        hosts = [
          {
            host = "keycloak.${trimprefix("${var.subdomain}.${var.base_domain}", ".")}"
            path = "/"
          },
          {
            host = "keycloak.${trimprefix("${var.subdomain}.${var.cluster_name}", ".")}.${var.base_domain}"
            path = "/"
          },
        ]
        tls = [{
          secretName = "keycloak-tls"
          hosts = [
            "keycloak.${trimprefix("${var.subdomain}.${var.base_domain}", ".")}",
            "keycloak.${trimprefix("${var.subdomain}.${var.cluster_name}", ".")}.${var.base_domain}"
          ]
        }]
      }
    }
  }]
}
