resource "null_resource" "dependencies" {
  triggers = var.dependency_ids
}

resource "argocd_project" "this" {
  metadata {
    name      = "kube-prometheus-stack"
    namespace = var.argocd_namespace
    annotations = {
      "devops-stack.io/argocd_namespace" = var.argocd_namespace
    }
  }

  spec {
    description  = "kube-prometheus-stack application project"
    source_repos = ["https://github.com/GersonRS/modern-devops-stack.git"]

    destination {
      name      = "in-cluster"
      namespace = var.namespace
    }

    # This extra destination block is needed by the v1/Service 
    # kube-prometheus-stack-coredns and kube-prometheus-stack-kubelet
    # that have to be inside kube-system.
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

resource "kubernetes_namespace" "kube_prometheus_stack_namespace" {
  metadata {
    name = var.namespace
  }
}


resource "kubernetes_secret" "thanos_object_storage_secret" {
  count = var.metrics_storage_main != null ? 1 : 0

  metadata {
    name      = "thanos-objectstorage"
    namespace = var.namespace
  }

  data = {
    "thanos.yaml" = yamlencode(var.metrics_storage_main.storage_config)
  }

  depends_on = [
    resource.kubernetes_namespace.kube_prometheus_stack_namespace
  ]
}

resource "random_password" "oauth2_cookie_secret" {
  length  = 16
  special = false
}

data "utils_deep_merge_yaml" "values" {
  input       = [for i in concat(local.helm_values, var.helm_values) : yamlencode(i)]
  append_list = var.deep_merge_append_list
}

resource "argocd_application" "this" {
  metadata {
    name      = "kube-prometheus-stack"
    namespace = var.argocd_namespace
  }

  timeouts {
    create = "15m"
    delete = "15m"
  }

  wait = var.app_autosync == { "allow_empty" = tobool(null), "prune" = tobool(null), "self_heal" = tobool(null) } ? false : true

  spec {
    project = argocd_project.this.metadata.0.name

    source {
      repo_url        = "https://github.com/GersonRS/modern-devops-stack.git"
      path            = "iac/modules/kube-prometheus-stack/charts/kube-prometheus-stack"
      target_revision = var.target_revision
      plugin {
        name = "kustomized-helm"
        env {
          name  = "HELM_VALUES"
          value = data.utils_deep_merge_yaml.values.output
        }
      }
    }

    destination {
      name      = "in-cluster"
      namespace = var.namespace
    }

    sync_policy {
      automated {
        allow_empty = var.app_autosync.allow_empty
        prune       = var.app_autosync.prune
        self_heal   = var.app_autosync.self_heal
      }

      retry {
        backoff {
          duration     = "20s"
          max_duration = "5m"
          factor       = "2"
        }
        limit = "3"
      }

      sync_options = [
        "CreateNamespace=false"
      ]
    }
  }

  depends_on = [
    resource.null_resource.dependencies,
    resource.kubernetes_secret.thanos_object_storage_secret,
    resource.kubernetes_namespace.kube_prometheus_stack_namespace
  ]
}

resource "null_resource" "this" {
  depends_on = [
    resource.argocd_application.this,
  ]
}
