output "vm_external_ip" {
  description = "Public IP address of the Kittygram VM"
  value       = yandex_vpc_address.kittygram.external_ipv4_address[0].address
}

output "kittygram_url" {
  description = "URL of the deployed Kittygram gateway"
  value       = "http://${yandex_vpc_address.kittygram.external_ipv4_address[0].address}:${var.gateway_port}"
}

output "app_bucket" {
  description = "Application Object Storage bucket name"
  value       = yandex_storage_bucket.app.bucket
}
