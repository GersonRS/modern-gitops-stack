resource "tls_private_key" "root" {
  algorithm = "ECDSA"
}

resource "tls_self_signed_cert" "root" {
  private_key_pem = tls_private_key.root.private_key_pem

  subject {
    common_name  = "devops-stack.camptocamp.com"
    organization = "Camptocamp, SA"
  }

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
  ]

  is_ca_certificate = true
}

resource "null_resource" "dependencies" {
  triggers = var.dependency_ids
}

resource "argocd_project" "this" {
  metadata {
    name      = "cert-manager"
    namespace = var.argocd_namespace
    annotations = {
      "devops-stack.io/argocd_namespace" = var.argocd_namespace
    }
  }

  spec {
    description  = "cert-manager application project"
    source_repos = ["https://github.com/GersonRS/modern-devops-stack.git"]

    destination {
      name      = "in-cluster"
      namespace = var.namespace
    }

    destination {
      name      = "in-cluster"
      namespace = "kube-system"
    }

    orphaned_resources {
      warn = true
    }

    cluster_resource_whitelist {
      group = "*"
      kind  = "*"
    }
  }
}

data "utils_deep_merge_yaml" "values" {
  input = [for i in concat(local.helm_values, concat([{
    cert-manager = {
      tlsCrt = base64encode(tls_self_signed_cert.root.cert_pem)
      tlsKey = base64encode(tls_private_key.root.private_key_pem)
    }
  }], var.helm_values)) : yamlencode(i)]
  append_list = var.deep_merge_append_list
}

resource "argocd_application" "this" {
  metadata {
    name      = "cert-manager"
    namespace = var.argocd_namespace
  }

  wait = var.app_autosync == { "allow_empty" = tobool(null), "prune" = tobool(null), "self_heal" = tobool(null) } ? false : true

  spec {
    project = argocd_project.this.metadata.0.name

    source {
      repo_url        = "https://github.com/GersonRS/modern-devops-stack.git"
      path            = "iac/modules/cert-manager/charts/cert-manager"
      target_revision = var.target_revision
      helm {
        values = data.utils_deep_merge_yaml.values.output
      }
    }

    destination {
      name      = "in-cluster"
      namespace = var.namespace
    }

    ignore_difference {
      group         = "admissionregistration.k8s.io"
      kind          = "ValidatingWebhookConfiguration"
      name          = "cert-manager-webhook"
      json_pointers = ["/webhooks/0/namespaceSelector/matchExpressions/2"]
    }

    sync_policy {
      automated {
        allow_empty = var.app_autosync.allow_empty
        prune       = var.app_autosync.prune
        self_heal   = var.app_autosync.self_heal
      }

      retry {
        limit = "5"
        backoff {
          duration     = "30s"
          max_duration = "2m"
          factor       = "2"
        }
      }

      sync_options = [
        "CreateNamespace=true"
      ]
    }
  }

  depends_on = [
    resource.null_resource.dependencies,
  ]
}

resource "null_resource" "this" {
  depends_on = [
    resource.argocd_application.this,
  ]
}
