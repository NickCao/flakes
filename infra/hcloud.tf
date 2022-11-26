resource "hcloud_server" "iad0" {
  name               = "iad0"
  server_type        = "cpx11"
  datacenter         = "ash-dc1"
  image              = "debian-11"
  delete_protection  = true
  rebuild_protection = true
  public_net {
    ipv4 = hcloud_primary_ip.iad0_v4.id
    ipv6 = hcloud_primary_ip.iad0_v6.id
  }
}

resource "hcloud_primary_ip" "iad0_v4" {
  name              = "iad0-v4"
  type              = "ipv4"
  datacenter        = "ash-dc1"
  assignee_type     = "server"
  auto_delete       = false
  delete_protection = true
}

resource "hcloud_primary_ip" "iad0_v6" {
  name              = "iad0-v6"
  type              = "ipv6"
  datacenter        = "ash-dc1"
  assignee_type     = "server"
  auto_delete       = false
  delete_protection = true
}

resource "hcloud_rdns" "iad0_v4" {
  server_id  = hcloud_server.iad0.id
  ip_address = hcloud_server.iad0.ipv4_address
  dns_ptr    = "iad0.nichi.link"
}

resource "hcloud_rdns" "iad0_v6" {
  server_id  = hcloud_server.iad0.id
  ip_address = hcloud_server.iad0.ipv6_address
  dns_ptr    = "iad0.nichi.link"
}
