locals {
  common_names = toset(["etcd-peer", "etcd-server", "etcd-client"])
  ca_csr_configs = { for cn in local.common_names : "cfssl/ca-csr-${cn}.json" => templatefile("${path.module}/cfssl/ca-csr.json", {
    cn : cn
  }) }
  etcd_assets = merge({
    "etcd-manager-ca.crt"  = tls_self_signed_cert.etcd_manager_ca[0].cert_pem
    "etcd-manager-ca.key"  = tls_private_key.etcd_manager_ca[0].private_key_pem
    "cfssl/ca-config.json" = file("${path.module}/cfssl/ca-config.json")
  }, local.ca_csr_configs)
}

resource "tls_private_key" "etcd_manager_ca" {
  count = module.this.enabled ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "etcd_manager_ca" {
  count = module.this.enabled ? 1 : 0

  key_algorithm   = tls_private_key.etcd_manager_ca[0].algorithm
  private_key_pem = tls_private_key.etcd_manager_ca[0].private_key_pem

  subject {
    common_name  = "etcd-manager-ca"
    organization = "etcd-manager"
  }

  is_ca_certificate     = true
  validity_period_hours = 87600

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]
}
