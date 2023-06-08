output "id" {
  value = module.loki-stack.id
}

output "loki_credentials" {
  value     = module.loki-stack.loki_credentials
  sensitive = true
}