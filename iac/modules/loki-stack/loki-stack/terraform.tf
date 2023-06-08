terraform {
  required_providers {
    argocd = {
      source  = "oboukili/argocd"
      version = ">= 4"
    }
    utils = {
      source  = "cloudposse/utils"
      version = ">= 1"
    }
    htpasswd = {
      source  = "loafoe/htpasswd"
      version = ">= 1"
    }
    random = {
      source  = "random"
      version = ">= 3"
    }
    null = {
      source  = "null"
      version = ">= 3"
    }
  }
}