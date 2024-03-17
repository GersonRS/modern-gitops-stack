locals {
  helm_values = [{
    metrics-server = {
      args = [
        var.kubelet_insecure_tls ? "--kubelet-insecure-tls" : null,
      ]
    }
  }]
}
