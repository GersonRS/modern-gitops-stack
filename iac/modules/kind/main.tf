resource "kind_cluster" "cluster" {
  name = var.cluster_name

  node_image = "kindest/node:${var.kubernetes_version}"

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      # kubeadm_config_patches = [
      #   "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      # ]

      # extra_port_mappings {
      #   container_port = 80
      #   host_port      = 80
      # }
      # extra_port_mappings {
      #   container_port = 443
      #   host_port      = 443
      # }
    }

    dynamic "node" {
      for_each = var.nodes
      content {
        role   = "worker"
        labels = node.value
      }
    }
  }
}

data "docker_network" "kind" {
  name       = "kind"
  depends_on = [kind_cluster.cluster]
}