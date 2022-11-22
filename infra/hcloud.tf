resource "hcloud_server" "iad0" {
  name               = "iad0"
  server_type        = "cpx11"
  location           = "ash"
  image              = "debian-11"
  delete_protection  = true
  rebuild_protection = true
}
