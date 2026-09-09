resource "yandex_vpc_security_group" "kittygram" {
  name       = "kittygram-sg"
  network_id = yandex_vpc_network.kittygram.id

  # Inbound SSH.
  ingress {
    protocol       = "TCP"
    description    = "SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  # Inbound HTTP to the Kittygram gateway.
  ingress {
    protocol       = "TCP"
    description    = "Gateway HTTP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = var.gateway_port
  }

  # All outbound traffic is allowed.
  egress {
    protocol       = "ANY"
    description    = "Allow all outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}
