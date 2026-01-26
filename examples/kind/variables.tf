variable "ssh_private_key" {
  description = <<-EOT
    Chave privada SSH no formato PEM utilizada para:
    - acesso a repositórios Git privados (deploy keys);
    - acesso SSH a nós do cluster quando necessário.

    Guarde essa chave como secret no provedor CI/CD e nunca a comite em texto claro no repositório.
  EOT
  type        = string
  sensitive   = true
  nullable    = false
}
