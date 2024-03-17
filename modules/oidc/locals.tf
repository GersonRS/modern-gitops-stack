locals {
  oidc = {
    issuer_url    = format("https://keycloak.%s.%s/realms/modern-gitops-stack", trimprefix("${var.subdomain}.${var.cluster_name}", "."), var.base_domain)
    oauth_url     = format("https://keycloak.%s.%s/realms/modern-gitops-stack/protocol/openid-connect/auth", trimprefix("${var.subdomain}.${var.cluster_name}", "."), var.base_domain)
    token_url     = format("https://keycloak.%s.%s/realms/modern-gitops-stack/protocol/openid-connect/token", trimprefix("${var.subdomain}.${var.cluster_name}", "."), var.base_domain)
    api_url       = format("https://keycloak.%s.%s/realms/modern-gitops-stack/protocol/openid-connect/userinfo", trimprefix("${var.subdomain}.${var.cluster_name}", "."), var.base_domain)
    client_id     = "modern-gitops-stack-applications"
    client_secret = resource.random_password.client_secret.result
    oauth2_proxy_extra_args = var.cluster_issuer != "letsencrypt-prod" ? [
      "--insecure-oidc-skip-issuer-verification=true",
      "--ssl-insecure-skip-verify=true",
    ] : []
  }
}
