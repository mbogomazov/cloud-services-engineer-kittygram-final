resource "yandex_vpc_network" "kittygram" {
  name = "kittygram-network"
}

resource "yandex_vpc_subnet" "kittygram" {
  name           = "kittygram-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.kittygram.id
  v4_cidr_blocks = ["10.10.0.0/24"]
}

# Reserved public IP. Keeping the address as a separate resource means the VM
# can be recreated without changing the public IP referenced by tests.yml and
# by the HOST deploy secret.
resource "yandex_vpc_address" "kittygram" {
  name = "kittygram-address"

  external_ipv4_address {
    zone_id = var.zone
  }
}
